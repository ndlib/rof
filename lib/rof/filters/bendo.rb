require 'date'

module ROF
  module Filters

    # If bendo server is set , add it into datasreams that contain an URl referencing bendo
    class Bendo
      def initialize(bendo=nil)
        @bendo = bendo
      end

      # for *-meta objects containing "URL", sub in bendo string if provided
      def process(obj_list, _fname)
        # NOTE: This was refactored to short-circuit the loop. A side-effect is that the code
        # is now returning the same object as was passed in. The previous behavior was that a
        # new object_list was created via the #map! method.
        return obj_list unless @bendo
        ends_meta = Regexp.new('(.+)-meta')
        obj_list.map! do |obj|
          obj.map do |name, value|
            if name =~ ends_meta
              if obj[name]["URL"]
                obj[name]["URL"] = obj[name]["URL"].sub("bendo:",@bendo)
              end
            end
          end
          obj
        end
      end
    end
  end
end
