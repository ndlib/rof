require 'rof/rdf_context'
require 'active_support/core_ext/array/wrap'
require 'rof/translators/jsonld_to_rof/accumulator'

module ROF
  module Translators
    # @api public
    #
    # Converts JSON LD (as a hash) into an ROF Hash through the `.call` method.
    #
    # @note Some predicates require explicit mapping where as others have an assumed mapping. At present all URLs for @context of JSON-LD documents must be registered.
    #
    # @see ROF::Translators::JsonldToRof.call for details on how the JSON-LD is converted
    # @see ROF::Translators::PredicateHandler.register for details on how Predicate URI's are mapped to nodes in the ROF document.
    # @see ROF::Translators::JsonldToRof::PredicateHandler
    # @see ROF::Translators::JsonldToRof::StatementHandler
    module JsonldToRof
      # NAMESPACES maps URI initial segments to shorter tags. This is used
      # since RDF nominally uses full URIs, but we prefer the shorter labels
      # using the tags.
      NAMESPACES = {
        'http://purl.org/ontology/bibo/' => 'bibo:',
        'info:fedora/fedora-system:def/relations-external#' => 'rels-ext:',
        'http://id.loc.gov/vocabulary/relators/' => 'mrel:',
        'http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#' => 'ebucore:',
        'https://library.nd.edu/ns/terms/' => 'nd:',
        'http://purl.org/dc/terms/' => 'dc:',
        'http://projecthydra.org/ns/relations#' => 'hydramata-rel:',
        'http://www.ndltd.org/standards/metadata/etdms/1.1/' => 'ms:',
        'https://curate.nd.edu/show/' => 'und:',
      }

      # The $1 will be the PID
      # @see Related specs for expected behavior
      REGEXP_FOR_A_CURATE_RDF_SUBJECT = %r{\Ahttps?://curate(?:[\w.]*).nd.edu/show/([[:alnum:]]+)/?}.freeze

      # @api public
      #
      # Convert's the given JSON-LD into an ROF document that can be used to batch ingest into Fedora.
      #
      # @param [Array<Hash>, Hash] jsonld - a Hash of JSON-LD data or an Array of JSON-LD Hashes
      # @param [Hash] config (included to conform to the loose interface of translators)
      # @return [Array<Hash>] An ROF document
      def self.call(jsonld, config)
        Array.wrap(jsonld).map! do |element|
          # Translate one JSON-LD item to ROF.
          #
          # We do it in two steps. First we group all the statements with the
          # same subject and remove blank nodes. This is our intermediate
          # representation.
          #
          # Then we turn that into an ROF object
          accumulator = Accumulator.new(base_rof)
          ir = {}

          statements = JSON::LD::API.toRdf(element)
          # #to_h gives a hash of subject => { predicate => [object] }
          statement_hash = statements.to_h
          statement_hash.each do |subject, predicates|
            # find the first subject that is a curate object.
            next unless subject.to_s =~ ROF::Translators::JsonldToRof::REGEXP_FOR_A_CURATE_RDF_SUBJECT
            pid = "und:#{$1}"

            ir = self.reduce_blank_nodes(statement_hash, subject)
            ir['pid'] = [pid]
            break
          end

          #
          # ir is a map with blank nodes removed. Turn it into ROF
          # We reuse the accumulator code, so the next step is to map the ir
          # into the accumulator.
          #
          # Define some helper functions to make it easier to add values
          add_all_values = lambda do |location, values|
            values.each do |v|
              accumulator.add_predicate_location_and_value(location, v)
            end
          end
          add_one_value = lambda do |location, values|
            accumulator.add_predicate_location_and_value(location, values.first, multiple: false)
          end

          ir.each do |prop, values|
            case prop
            when 'pid'
              accumulator.add_pid(values.first)
            when 'nd:depositor'
              accumulator.register_properties('depositor', values.first)
            when 'nd:owner'
              accumulator.register_properties('owner', values.first)
            when 'nd:representativeFile'
              accumulator.register_properties('representative', values.first)
            when 'nd:accessEdit'
              add_all_values.call(['rights', 'edit'], values)
            when 'nd:accessRead'
              add_all_values.call(['rights', 'read'], values)
            when 'nd:accessEditGroup'
              add_all_values.call(['rights', 'edit-groups'], values)
            when 'nd:accessReadGroup'
              add_all_values.call(['rights', 'read-groups'], values)
            when 'nd:accessEmbargoDate'
              add_one_value.call(['rights', 'embargo-date'], values)
            when 'nd:afmodel'
              add_all_values.call(['af-model'], values)
            when 'nd:filename'
              add_one_value.call(['content-file'], values)
            when 'nd:alephIdentifier'
              add_one_value.call(['metadata', 'nd:alephIdentifier'], values)
            when 'nd:bendoitem'
              add_one_value.call(['bendo-item'], values)
            when 'nd:characterization'
              add_one_value.call(['characterization'], values)
            when 'nd:content', 'nd:thumbnail', 'nd:mimetype'
              # Discard these keys when mapping from JSON-LD to ROF
            when /^rels-ext:/
              add_all_values.call(['rels-ext', prop.delete_prefix("rels-ext:")], values)
            when 'hydramata-rel:hasEditorGroup'
              add_all_values.call(['rels-ext', 'hydramata-rel:hasEditorGroup'], values)
              add_all_values.call(['rights', 'edit-groups'], values)
            when /^hydramata-rel:/
              add_all_values.call(['rels-ext', prop], values)
            else
              add_all_values.call(['metadata', prop], values)
            end
          end

          accumulator.to_rof
        end
      end

      # reduce_blank_nodes converts all URIs into their shorter namespaced
      # versions, and then replaces any objects that are labels for blank nodes
      # with a hash of all the predicates having that blank node as a subject.
      # This replacement is carried on recursively.
      #
      # e.g. The value
      #   { "dc:creator" => "_:b1" }
      # and in the everything_hash
      #   "_:b1" => { "dc:identifier" => "1234", "rdf:label" => "Zissou" }
      # is transformed into
      # { "dc:creator" => { "dc:identifier" => "1234", "rdf:label" => "Zissou" }}
      #
      def self.reduce_blank_nodes(everything_hash, this_subject)
        return '' unless everything_hash.key?(this_subject)
        result = {}
        predicates = everything_hash[this_subject]
        predicates.each do |predicate, objects|
          ns_predicate = self.shorten_predicate(predicate.to_s)
          result[ns_predicate] = objects.map do |object|
            if object.anonymous?
              self.reduce_blank_nodes(everything_hash, object)
            elsif object.uri?
              self.shorten_predicate(object.to_s)
            else
              object.to_s
            end
          end
        end
        result
      end

      # shorten_predicate turns a URI p into either a shorter namespaced
      # version using the NAMESPACES hash as a mapping, or returns p if there
      # is no matching namespace.
      def self.shorten_predicate(p)
        NAMESPACES.each do |prefix, abbrev|
          if p.start_with?(prefix)
            return abbrev + p.delete_prefix(prefix)
          end
        end
        p
      end

      def self.base_rof
        { "type" => "fobject", "metadata" => { "@context" => ROF::RdfContext }, "rels-ext" => { "@context" => ROF::RelsExtRefContext } }
      end
    end
  end
end
