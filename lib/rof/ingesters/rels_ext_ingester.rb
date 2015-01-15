require 'rdf'
require 'json/ld'
require 'rdf/rdfxml'

module ROF
  module Ingesters
    class RelsExtIngester
      def self.call(attributes)
        new(attributes).call
      end

      # :models is a list of fedora content models this item has
      # :item is the hash of the ROF item
      # :fdoc is an optional fedora document to save to
      # :pid is the namespaced identifier of this item
      attr_reader :models, :item, :fdoc, :pid
      def initialize(attributes = {})
        @models = attributes.fetch(:models)
        @item = attributes.fetch(:item)
        @pid = item.fetch('pid')
        @fdoc = attributes.fetch(:fedora_document, nil)
      end

      def call
        content = build_content
        persist(content)
        content
      end

      private

      def rels_ext
        item.fetch('rels-ext', {})
      end

      def build_content
        # this is ugly to work around addRelationship bug in 3.6.x
        # (See bugs FCREPO-1191 and FCREPO-1187)

        # build up a json-ld object, and then persist that (into XML!)
        input = rels_ext
        context = input.fetch("@context", {}).merge(
          "@vocab" => "info:fedora/fedora-system:def/relations-external#",
          "hasModel" => {"@id" => "info:fedora/fedora-system:def/model#hasModel",
                      "@type" => "@id"},
          "@base" => "info:fedora/"
        )
        input["@context"] = context
        input["@id"] = "info:fedora/#{pid}"

        input["hasModel"] = models

        # RELS-EXT should only contain references to other (internal) fedora
        # objects. Rewrite them to have prefix "info:fedora/".
        # Also need to make sure json-ld interprets each of these object
        # references as an IRI instead of a string.
        input.each do |relation, targets|
          next if relation[0] == "@" || relation == "hasModel"
          targets = [targets] if targets.is_a? String
          input[relation] = targets.map do |target|
            {"@id" => "info:fedora/#{target}"}
          end
        end

        graph = RDF::Graph.new << JSON::LD::API.toRdf(input)
        graph.dump(:rdfxml)
      end
      def persist(content)
        if fdoc
          ds = fdoc['RELS-EXT']
          ds.content = content
          ds.mimeType = "application/rdf+xml"
          ds.save
        else
          true
        end
      end
    end
  end
end
