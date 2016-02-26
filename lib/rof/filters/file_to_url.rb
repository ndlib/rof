module ROF
  module Filters
    # Convert any content datastream files into a bendo URL, and alter the rof
    # to use the URL and not upload the file to fedora directly. The bendo URL
    # will only exist for items having a bendo-item id set. The URL generated
    # supposes the file keeps the same relative path the item originally had in
    # the rof file.
    class FileToUrl
      def initialize()
      end

      def process(obj_list)
        obj_list.map! do |obj|
          bendo_item = obj['bendo-item']
          content_file = obj['content-file']
          if bendo_item && content_file
            new_meta = obj.fetch('content-meta', {})
            new_meta['URL'] = "bendo:/item/#{bendo_item}/#{content_file}"
            obj['content-meta'] = new_meta
            obj.delete('content-file')
          end
          obj
        end
      end
    end
  end
end
