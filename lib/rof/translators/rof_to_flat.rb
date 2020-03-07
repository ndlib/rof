require 'rof/translator'
require 'rof/flat'
require 'json'

module ROF::Translators
  # translate a ROF file into an array of Flat records
  class RofToFlat < ROF::Translator
    def self.call(input_rof, config = {})
      results = input_rof.map do |item|
        v = ROF::Flat.new
        v.add('pid', item['pid'])
        v.add('rof-type', item['type'])
        v.add('af-model', item['af-model'])
        v.add('bendo-item', item['bendo-item'])
        decode_rights(v, item)

        item['rels-ext']&.each do |predicate, value|
          next if predicate == "hasModel" || predicate == "@context" || predicate == "@id"
          p = make_predicate_nice(predicate)
          v.add(p, Array.wrap(value))
        end

        props = ROF::Utility.prop_ds_to_values(item['properties'])
        v.add('owner', props[:owner])
        v.add('representative', props[:representative])
        v.add('depositor', props[:depositor])
        m = item['content-meta']
        if m
          v.set('file-url', m['URL'])
          v.set('file-mime-type', m['mime-type'])
          v.set('filename', m['label'])
        end

        # sometimes json-ld metadata gets serialized using a @graph.
        # this complicates the decoding since we need to treat it as RDF data.
        md = decode_metadata(item['metadata'])
        md.each do |predicate, values|
          v.add(predicate, values)
        end

        v
      end
    end

    # try to decode the rights by looking at the rels-ext and the rights metadata
    def self.decode_rights(target, item)
      # first move any relevant rels-ext links back to the rights
      r = item['rels-ext']
      if r
        regexp_fetch = lambda do |property, pattern|
          r.delete_if do |k, v|
            if k =~ pattern
              target.add_uniq(property, v)
              true
            else
              false
            end
          end
        end
        regexp_fetch.call('read-person', /hasViewer$/)
        regexp_fetch.call('read-group', /hasViewerGroup/)
        regexp_fetch.call('edit-person', /hasEditor$/)
        regexp_fetch.call('edit-group', /hasEditorGroup/)
        item['rels-ext'] = r
      end

      # now merge everything in the rights block
      r = item['rights']
      if r
        target.add_uniq('discover-person', r['discover'])
        target.add_uniq('discover-group', r['discover-groups'])
        target.add_uniq('read-person', r['read'])
        target.add_uniq('read-group', r['read-groups'])
        target.add_uniq('edit-person', r['edit'])
        target.add_uniq('edit-group', r['edit-groups'])

        target.add('embargo-date', r['embargo-date'])
      end
    end

    # treat the metadata as RDF data, and turn into a hash
    # of key (string) => Array (of string).
    def self.decode_metadata(metadata)
      graph = RDF::Graph.new << JSON::LD::API.toRdf(metadata)
      # first deal with statements with blank node subjects
      blanks = {}
      graph.each do |statement|
        subject = statement.subject
        next unless subject.node?
        blanks[subject] = blanks.fetch(subject, []) << statement
      end

      # figure out which subject is the root
      # Try to choose a non-blank node, but default to subject with the most statements
      root = graph.subjects.detect (-> {blanks.max_by {|k,v| v.length}.first}) {|x| !x.node?}

      # now deal with everything else
      result = {}
      graph.each do |statement|
        next unless statement.subject == root
        predicate = make_predicate_nice(statement.predicate.pname)
        object = statement.object
        objvalue = if object.literal?
                      object.value
                    elsif object.node?
                      StatementsToDoubleCaret(blanks[object])
                    end
        result[predicate] = result.fetch(predicate, []) << objvalue unless objvalue.nil?
      end
      # the RDF Gem will return statements in a random order, which is valid RDF
      # behavior since graphs are not ordered. This has the side-effect that
      # things like lists of author names are never the same twice. Sort these
      # names so that the rof->flat translation is deterministic. Look into not
      # using RDF to store items where ordering is important.
      result.each_value { |v| v.sort! }
      result
    end

    # convert a list of RDF statements into a double caret string
    def self.StatementsToDoubleCaret(statement_list)
      return nil if statement_list.nil?  # e.g. undefined blank node referenced
      h = {}
      statement_list.each do |statement|
        predicate = make_predicate_nice(statement.predicate.pname)
        h[predicate] = statement.object.value
      end
      ROF::Utility.EncodeDoubleCaret(h, true)
    end

    # convert long urls to a namespaced url
    def self.make_predicate_nice(ugly_name)
      ROF::RdfContext.each do |k,v|
        next unless v.is_a?(String)
        if ugly_name.start_with?(v)
          return ugly_name.sub(v, k + ":")
        end
      end
      ugly_name
    end

  end
end
