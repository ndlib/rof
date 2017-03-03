module ROF
  module Filters

    # If bendo server is set , add it into datasreams that contain an URl referencing bendo
    class Bendo
      def initialize(options = {})
        @bendo = options.fetch(:bendo_info)
      end

      # for *-meta objects containing "URL", sub in bendo string if provided
      def process(obj_list)
        # NOTE: This was refactored to short-circuit the loop. A side-effect is that the code
        # is now returning the same object as was passed in. The previous behavior was that a
        # new object_list was created via the #map! method.
        return obj_list unless @bendo
        key_name_ends_in_meta_regexp = Regexp.new('(.+)-meta')
        obj_list.map! do |obj|
          obj.map do |key_name, value|
            if key_name =~ key_name_ends_in_meta_regexp
              if obj[key_name]["URL"]
                obj[key_name]["URL"] = obj[key_name]["URL"].sub("bendo:", @bendo)
              end
            end
          end
          obj
        end
      end
    end
  end
end
