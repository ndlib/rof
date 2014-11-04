
module ROF
  module Filters
    # Expand objects of type "Work(-(.+))?" into a
    # constelation of "fobjects".
    # Makes a fobject/generic_file for each file
    # adds a depositor
    # turns original object into an fobject/$1
    # and copies the access to each fobject.
    class Work

      def initialize
        @random = Random.new
      end

      def process(obj_list)
        obj_list.map! { |x| process_one(x) }
        obj_list.flatten!
      end

      def process_one(obj)
        return obj unless obj["type"].start_with?("Work")
        model = if obj["type"] =~ /Work(-(.+))?/
                 $2
               else
                 "GenericWork"
               end
        main_obj = {
          "type" => "fobject",
          "af-model" => model,
          "pid" => obj.fetch("pid", "$(#{@random.rand})"),
          "rights" => obj["rights"],
          "properties" => properties_ds(obj["owner"]),
          "properties-meta" => {
            "mime-type" => "text/xml"
          },
          "metadata" => obj["metadata"]
        }
        result = [main_obj]
        return result if obj["files"].nil?
        obj["files"].each do |fname|
          f_obj = {
            "type" => "fobject",
            "af-model" => "GenericFile",
            "rights" => obj["rights"],
            "properties" => properties_ds(obj["owner"]),
            "properties-meta" => {
              "mime-type" => "text/xml"
            },
            "rels-ext" => {
              "isPartOf" => [main_obj["pid"]]
            },
            "content-file" => fname,
            "content-meta" => {
              "label" => fname
            }
          }
          result << f_obj
        end
        result
      end

      def properties_ds(owner)
        %Q{<fields>
<depositor>batch_ingest</depositor>
<owner>#{owner}</owner>
</fields>
}
      end
    end
  end
end
