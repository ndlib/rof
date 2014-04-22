module ROF
  module Ingesters
    class RightsMetadataIngester
      def self.call(attributes)
        new(attributes).call
      end

      attr_reader :item, :fdoc
      def initialize(attributes = {})
        @item = attributes.fetch(:item)
        @fdoc = attributes.fetch(:fedora_document, nil)
      end

      def call
        rights = item["rights"]
        return if rights.nil?
        #
        # we really should be building this using an xml engine.
        #
        content = %Q{<rightsMetadata xmlns="http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1" version="0.1">\n}
        # TODO(dbrower): Does the copyright need to be exposed in the rof?
        content += %Q{  <copyright>\n    <human type="title"/>\n    <human type="description"/>\n    <machine type="uri"/>\n  </copyright>\n}
        content += format_rights_section("discover", rights["discover"], rights["discover-groups"])
        content += format_rights_section("read", rights["read"], rights["read-groups"])
        content += format_rights_section("edit", rights["edit"], rights["edit-groups"])
        # TODO(dbrower): expose embargo information
        content += %Q{  <embargo>\n    <human/>\n    <machine/>\n  </embargo>\n}
        content += %Q{</rightsMetadata>\n}

        if fdoc
          ds = fdoc['rightsMetadata']
          ds.mimeType = 'text/xml'
          ds.content = content
          ds.save
        end
        content
      end

      private
      def format_rights_section(section_name, people, groups)
        people = [people] if people.is_a? String
        groups = [groups] if groups.is_a? String
        result = "  <access type=\"#{section_name}\">\n    <human/>\n"
        if people || groups
          result += "    <machine>\n"
          (people || []).each do |person|
            result += "      <person>#{person}</person>\n"
          end
          (groups || []).each do |group|
            result += "      <group>#{group}</group>\n"
          end
          result += "    </machine>\n"
        else
          result += "    <machine/>\n"
        end
        result += "  </access>\n"
        result
      end
    end
  end
end
