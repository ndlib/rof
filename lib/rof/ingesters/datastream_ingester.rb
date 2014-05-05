module ROF
  module Ingesters
    class DatastreamIngester
      def self.call(attributes)
        new(attributes).call
      end

      attr_reader :dsname, :item, :fdoc, :search_paths, :ds_content
      attr_reader :metadata_payload, :ds_filename
      def initialize(attributes = {})
        @dsname = attributes.fetch(:dsname)
        @item = attributes.fetch(:item)
        @search_paths = attributes.fetch(:search_paths)
        @fdoc = attributes.fetch(:fedora_document, nil)
        @ds_content = item[dsname]
        @ds_filename = item["#{dsname}-file"]
        @metadata_payload = attributes.fetch(:metadata_payload) { default_metadata_payload }
        if ds_filename && ds_content
          raise SourceError.new("Both #{dsname} and #{dsname}-file are present.")
        end
      end

      def call
        if item["#{dsname}-meta"]
          metadata_payload.merge!(item["#{dsname}-meta"])
        end

        # NOTE(dbrower): this could be refactored a bit. I was trying to keep the
        # same path for whether fdoc is nil or not as much as possible.
        ds = nil
        if fdoc
          ds = fdoc[dsname]
          # TODO(dbrower): maybe verify these options to be within bounds?
          ds.controlGroup = metadata_payload.fetch("control-group")
          ds.dsLabel = metadata_payload.fetch("label")
          ds.versionable = metadata_payload.fetch("versionable")
          ds.mimeType = metadata_payload.fetch("mime-type")
        end
        need_close = false
        if ds_filename
          ds_content = self.find_file_and_open(ds_filename, search_paths, "r")
          need_close = true
        end
        if ds
          ds.content = ds_content if ds_content
          ds.save
        end
      ensure
        ds_content.close if ds_content && need_close
      end

      private
      def default_metadata_payload
        {
          "mime-type" => "text/plain",
          "label" => "",
          "versionable" => true,
          "control-group" => "M",
        }
      end
    end
  end
end
