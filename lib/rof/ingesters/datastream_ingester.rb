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
      end
    end
  end
end
