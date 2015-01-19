
require 'date'

module ROF
  module Filters
    # Generate a JSON object from a given ROF file which for each collection
    # referenced in the ROF file, a key with its value being a list of ids
    # of the ROF objects belonging to that collection.
    # e.g.
    # [{"pid" : "temp:1", "collections" : ["A"]},
    #  {"pid" : "temp:2", "collections" : ["B", A"]}]
    # will generate the JSON object
    # { "A" : ["temp:1", "temp:2"],
    #   "B" : ["temp:2"]
    # }
    class Collections
      def process(obj_list)
        result = {}
        obj_list.map do |obj|
          next unless obj["pid"]
          next if obj["collections"].nil?
          obj["collections"].each do |collection|
            result[collection] = result.fetch(collection, []) << obj["pid"]
          end
        end
        result
      end
    end
  end
end
