module ROF
  module Ingesters
    class RelsExtIngester
      def self.call(attributes)
        new(attributes).call
      end

      attr_reader :models, :item, :fdoc
      def initialize(attributes = {})
        @models = attributes.fetch(:models)
        @item = attributes.fetch(:item)
        @fdoc = attributes.fetch(:fedora_document, nil)
      end

      def call
        rels_ext = item['rels-ext'] || {}
        pid = item['pid']
        # this is ugly to work around addRelationship bug in 3.6.x
        # (See bugs FCREPO-1191 and FCREPO-1187)
        content = '<rdf:RDF xmlns:ns0="info:fedora/fedora-system:def/model#" xmlns:ns1="info:fedora/fedora-system:def/relations-external#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">'
        content += %Q{<rdf:Description rdf:about="info:fedora/#{pid}">}
        models.each do |model|
          content += "<ns0:hasModel rdf:resource=\"#{model}\"/>"
        end
        rels_ext.each do |relation, targets|
          # TODO(dbrower): handle rels_ext correctly. probably part of handling
          # XML correctly
          targets = [targets] if targets.is_a? String
          targets.each do |target|
            content += "<ns1:#{relation} rdf:resource=\"#{target}\"/>"
          end
        end
        content += '</rdf:Description></rdf:RDF>'
        if fdoc
          ds = fdoc['RELS-EXT']
          ds.content = content
          ds.mimeType = "application/rdf+xml"
          ds.save
        end
        content
      end
    end
  end
end
