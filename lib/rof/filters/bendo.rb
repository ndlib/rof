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
        ends_meta = Regexp.new('(.+)-meta')
        obj_list.map! do |obj|
          obj.map do |name, value|
            if name =~ ends_meta
              if obj[name]["URL"] && @bendo
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
