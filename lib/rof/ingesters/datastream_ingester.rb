module ROF
  module Ingesters
    class DatastreamIngester
      def self.call(attributes)
        new(attributes).call
      end

      attr_reader :dsname, :item, :fdoc, :search_paths
      def initialize(attributes = {})
        @dsname = attributes.fetch(:dsname)
        @item = attributes.fetch(:item)
        @search_paths = attributes.fetch(:search_paths)
        @fdoc = attributes.fetch(:fedora_document, nil)
      end

      def call
        # What kind of content is there?
        ds_content = item[dsname]
        ds_filename = item["#{dsname}-file"]
        if ds_filename && ds_content
          raise SourceError.new("Both #{dsname} and #{dsname}-file are present.")
        end

        md = {"mime-type" => "text/plain",
              "label" => "",
              "versionable" => true,
              "control-group" => "M",
              }
        if item["#{dsname}-meta"]
          md.merge!(item["#{dsname}-meta"])
        end

        # NOTE(dbrower): this could be refactored a bit. I was trying to keep the
        # same path for whether fdoc is nil or not as much as possible.
        ds = nil
        if fdoc
          ds = fdoc[dsname]
          # TODO(dbrower): maybe verify these options to be within bounds?
          ds.controlGroup = md["control-group"]
          ds.dsLabel = md["label"]
          ds.versionable = md["versionable"]
          ds.mimeType = md["mime-type"]
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
      ds_content.close if ds_content && need_close      end
    end
  end
end
