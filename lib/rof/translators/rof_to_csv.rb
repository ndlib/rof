# frozen_string_literal: true

require 'rof/translator'
require 'csv'
require 'json'
require 'json/ld'

module ROF::Translators
  # translate a ROF file into a CSV file
  #
  # The goal is to create a perfect mapping from csv ==> rof ==> csv.
  # We will modify the csv conventions as needed to get this to happen.
  #
  # We expect this to be called on rof files already generated from csv_to_rof. but that may not
  # be the case, so the code below tries to handle the general case as much as possible. With that
  # said, our aim is just handling the ROF files that have the curatend object model. (Since ROF objects
  # can encode arbitrary fedora 3 objects, which have just too much variety).
  #
  # Returns the contents of the csv file as a string
  class RofToCsv < ROF::Translator
    def self.call(input_rof, config = {})
      # we first scan the rof and turn each rof object into a single-level map of column-name --> value
      seen_names = []
      add_field = lambda do |itm, col, val|
        return if val.nil?

        seen_names << col unless seen_names.include?(col)
        itm[col] = val
      end
      results = []
      input_rof.each do |item|
        v = {}
        add_field.call(v, 'pid', item['pid'])
        add_field.call(v, 'rof-type', item['type'])
        add_field.call(v, 'af-model', item['af-model'])
        add_field.call(v, 'bendo-item', item['bendo-item'])
        add_field.call(v, 'access', decode_rights(item))

        item['rels-ext']&.each do |predicate, value|
          next if predicate == 'hasModel'
          next if predicate == '@context'
          next if predicate == '@id'

          value = value.join('|') if value.is_a?(Array)
          add_field.call(v, predicate, value)
        end

        props = ROF::Utility.prop_ds_to_values(item['properties'])
        add_field.call(v, 'owner', props[:owner])
        add_field.call(v, 'representative', props[:representative])
        m = item['content-meta']
        if m
          add_field.call(v, 'file-URL', m['URL'])
          add_field.call(v, 'file-mime-type', m['mime-type'])
          add_field.call(v, 'filename', m['label'])
          # need to recover the path structure from the bendo url so we can find the file
          # in the local directory. Should this be a field if it can be derived from another one?
          if m['URL']
            add_field.call(v, 'file-with-path', m['URL'].sub(%r{.*/item/\w+/}, ''))
          end
        end

        # sometimes json-ld metadata gets serialized using a @graph.
        # this complicates the decoding since we need to treat it as RDF data.
        md = decode_metadata(item['metadata'], config.fetch(:sort_keys, nil))
        md.each do |predicate, values|
          add_field.call(v, predicate, values.join('|'))
        end

        results.push(v)
      end

      # Output the rows as a csv. Do this last since we need to know all of the
      # column names at the beginning. While we don't do this at the moment, the
      # column names could be reordered to some cannonical ordering.
      #
      # Returns a string containing the contents of the CSV file.
      seen_names.sort! if config.fetch(:sort_keys, nil) # for testing
      CSV.generate do |csv|
        csv << seen_names
        results.each do |v|
          csv << seen_names.map { |name| v[name] }
        end
      end
    end

    # try to decode the rights by looking at the rels-ext and the rights metadata
    def self.decode_rights(item)
      # first move any relevant rels-ext links back to the rights
      rights = {}
      if item['rels-ext']
        r = item['rels-ext']
        rights['read'] = Array(r.delete('hasViewer'))
        rights['read-groups'] = Array(r.delete('hasViewerGroup'))
        rights['edit'] = Array(r.delete('hasEditor'))
        rights['edit-groups'] = Array(r.delete('hasEditorGroup'))
        rights.delete_if { |_k, v| v.nil? || v.empty? }
      end

      # now merge in anything in the rights block
      if item['rights']
        r = item['rights']
        extend_entry = lambda do |field, value|
          rights[field] = rights.fetch(field, []).concat(Array(value)).uniq
        end

        extend_entry.call('discover', r['discover'])
        extend_entry.call('discover-groups', r['discover-groups'])
        extend_entry.call('read', r['read'])
        extend_entry.call('read-groups', r['read-groups'])
        extend_entry.call('edit', r['edit'])
        extend_entry.call('edit-groups', r['edit-groups'])
        rights['embargo-date'] = r['embargo-date']
        rights.delete_if { |_k, v| v.nil? || v.empty? }
      end

      ROF::Access.encode(rights)
    end

    # Decode the metadata and turn into a hash of
    # key (string) => Array (of string).
    def self.decode_metadata(metadata, sort_keys = false)
      # Since interpreting the metadata as RDF loses the
      # ordering of elements having the same property (e.g. the ordering
      # of authors), only go the RDF route if we have to.
      if metadata['@graph']
        # this is json-ld. so we have to do this.
        return decode_metadata_rdf(metadata, sort_keys)
      end

      metadata.delete_if { |k, _v| k == '@context' || k == '@id' }
      # no Hash#transform_values in ruby 2.3.8
      result = {}
      metadata.each do |k, v|
        result[k] = Array.wrap(v).map do |vv|
          if vv.is_a?(Hash)
            ROF::Utility.EncodeDoubleCaret(vv, true)
          else
            vv
          end
        end
      end
      result
    end

    def self.decode_metadata_rdf(metadata, sort_keys = false)
      graph = RDF::Graph.new << JSON::LD::API.toRdf(metadata)

      # figure out which subject is the root
      # Try to choose a non-blank node, but default to first subject otherwise
      root = graph.subjects.detect (-> { graph.first_subject }) { |x| !x.node? }

      # group statements by subject. we only care about those with a blank node
      # as a subject
      blanks = {}
      graph.each do |statement|
        subject = statement.subject
        next unless subject.node?

        blanks[subject] = blanks.fetch(subject, []) << statement
      end

      # now look at those statements having the root as the subject.
      result = {}
      graph.each do |statement|
        next unless statement.subject == root

        predicate = make_predicate_nice(statement.predicate.pname)
        object = statement.object
        objvalue = if object.literal?
                     object.value
                   elsif object.node?
                     StatementsToDoubleCaret(blanks[object], sort_keys)
                    end
        unless objvalue.nil?
          result[predicate] = result.fetch(predicate, []) << objvalue
        end
      end
      result
    end

    def self.StatementsToDoubleCaret(statement_list, sort_keys)
      return nil if statement_list.nil? # e.g. undefined blank node referenced

      h = {}
      statement_list.each do |statement|
        predicate = make_predicate_nice(statement.predicate.pname)
        h[predicate] = statement.object.value
      end
      ROF::Utility.EncodeDoubleCaret(h, sort_keys)
    end

    # try to replace an initial segment of `ugly_name` with a
    # namespace prefix. return the whole thing if we can't find
    # such a prefix.
    def self.make_predicate_nice(ugly_name)
      ROF::RdfContext.each do |k, v|
        next unless v.is_a?(String)
        return ugly_name.sub(v, k + ':') if ugly_name.start_with?(v)
      end
      ugly_name
    end
  end
end
