require 'rof/rdf_context'
require 'active_support/core_ext/array/wrap'
require 'rof/translators/jsonld_to_rof/predicate_handler'
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
      PredicateHandler.register('http://purl.org/ontology/bibo/') do |handler|
        handler.namespace_prefix('bibo:')
        handler.within(['metadata'])
      end
      PredicateHandler.register('info:fedora/fedora-system:def/relations-external#') do |handler|
        handler.namespace_prefix('')
        handler.within(['rels-ext'])
      end
      PredicateHandler.register('http://id.loc.gov/vocabulary/relators/') do |handler|
        handler.namespace_prefix('mrel:')
        handler.within(['metadata'])
      end
      PredicateHandler.register('http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#') do |handler|
        handler.namespace_prefix('ebucore:')
        handler.within(['metadata'])
      end

      PredicateHandler.register('https://library.nd.edu/ns/terms/') do |handler|
        handler.namespace_prefix('nd:')
        handler.within(['metadata'])
        handler.map('accessEdit', to: ['rights', 'edit'], force: true)
        handler.map('accessRead', to: ['rights', 'read'], force: true)
        handler.map('accessEditGroup', to: ['rights', 'edit-groups'], force: true)
        handler.map('accessReadGroup', to: ['rights', 'read-groups'], force: true)
        handler.map('accessEmbargoDate', to: ['rights', 'embargo-date'], multiple: false, force: true)
        handler.map('afmodel', to: ["af-model"], force: true)
        # map nd:filename to content-file 
        handler.map('filename', to: [ 'content-file' ], multiple: false, force: true)
        handler.map('alephIdentifier', to: ['alephIdentifier'], multiple: false)
        handler.map('bendoitem', to: ["bendo-item"], multiple: false, force: true)
        handler.map('depositor') do |object, accumulator|
          accumulator.register_properties('depositor', object)
        end
        handler.map('owner') do |object, accumulator|
          accumulator.register_properties('owner', object)
        end
        handler.map('representativeFile', multiple: false) do |object, accumulator|
          accumulator.register_properties('representative', object)
        end
        handler.map('characterization', to: ['characterization'], multiple: false, force: true)

        # Discard these keys when mapping from JSON-LD to ROF
        handler.skip('content')
        handler.skip('thumbnail')
        handler.skip('mimetype')
      end

      PredicateHandler.register('http://purl.org/dc/terms/') do |handler|
        handler.namespace_prefix('dc:')
        handler.within(['metadata'])
        handler.map('contributor', to: ['metadata', 'dc:contributor', 'dc:contributor'], force: true)
      end

      PredicateHandler.register('http://projecthydra.org/ns/relations#') do |handler|
        handler.map('hasEditor', to: ['rels-ext', 'hydramata-rel:hasEditor'])
        # We need to map the hasEditorGroup predicate to two different locations in the ROF
        handler.map('hasEditorGroup', to: ['rels-ext', 'hydramata-rel:hasEditorGroup'], force: true)
        handler.map('hasEditorGroup', to: ['rights', 'edit-groups'], force: true)
      end

      PredicateHandler.register('http://www.ndltd.org/standards/metadata/etdms/1.1/') do |handler|
        handler.within(['metadata', 'ms:degree'])
        handler.namespace_prefix('ms:')
        handler.map('role', to: ['metadata', 'dc:contributor', 'ms:role'], force: true)
      end

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
          # The difficulty is that we must deal with the JSON-LD data as RDF. So we need to handle
          # it triple by triple. The first complexity is that there may be blank nodes. The second
          # complexity is translating it to ROF. Rather than deal with both in one pass, we do three!
          # The first pass looks at all the triples and organizes them by subject.
          # The second pass recursively groups blank nodes and internal references.
          # The thrid puts everything into ROF format.
          accumulator = Accumulator.new(base_rof)
          JSON::LD::API.toRdf(element) do |statement|
            case statement.subject
            when RDF::URI
              # Handle the various CurateND environments instead of just curate.nd.edu
              if statement.subject.to_s =~ ROF::Translators::JsonldToRof::REGEXP_FOR_A_CURATE_RDF_SUBJECT
                pid = "und:#{$1}"
                accumulator.add_pid(pid)
              end
              PredicateObjectHandler.call(statement.predicate, statement.object, accumulator)
            when RDF::Node
              accumulator.add_blank_node(statement)
            else
              raise UnhandledRdfSubjectError, "Unable to determine subject handler for #{statement.inspect}"
            end
          end
          accumulator.to_rof
        end
      end

      def self.base_rof
        { "type" => "fobject", "metadata" => { "@context" => ROF::RdfContext }, "rels-ext" => { "@context" => ROF::RelsExtRefContext } }
      end

      class UnhandledRdfSubjectError < RuntimeError
      end
    end
  end
end
