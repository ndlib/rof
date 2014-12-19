require 'mime-types'

module ROF
  module Filters
    # Expand objects of type "Work(-(.+))?" into a
    # constelation of "fobjects".
    # Makes a fobject/generic_file for each file
    # adds a depositor
    # turns original object into an fobject/$1
    # and copies the access to each fobject.
    class Work

      WORK_TYPE_WITH_PREFIX_PATTERN = /^[Ww]ork(-(.+))?/.freeze

      WORK_TYPES = {
        # csv name => af-model
        "article" => "Article",
        "dataset" => "Dataset",
        "document" => "Document",
        "etd" => "Etd",
        "image" => "Image"
      }.freeze

      def initialize
        @seq = 0
      end

      def process(obj_list)
        obj_list.map! { |x| process_one_work(x) }
        obj_list.flatten!
      end

      # given a single object, return a list (possibly empty) of new objects
      # to replace the one given
      def process_one_work(obj)
        model = decode_work_type(obj)
        return [obj] if model.nil?

        main_obj = {
          "type" => "fobject",
          "af-model" => model,
          "pid" => obj.fetch("pid", next_label),
          "rights" => obj["rights"],
          "properties" => properties_ds(obj["owner"]),
          "properties-meta" => {
            "mime-type" => "text/xml"
          },
          "metadata" => obj["metadata"]
        }
        result = [main_obj]
        return result if obj["files"].nil?
        # make the first file be the representative thumbnail
        thumb_rep = nil
        obj["files"].each do |fname|
          mimetype = MIME::Types.of(fname)
          mimetype = mimetype.empty? ? "application/octet-stream" : mimetype.first.content_type
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
              "label" => fname,
              "mime-type" => mimetype
            },
            "metadata" => {
              "@context" => ROF::RdfContext,
              "dc:title" => fname
            }
          }
          if thumb_rep.nil?
            thumb_rep = next_label
            f_obj["pid"] = thumb_rep
            main_obj["properties"] = properties_ds(obj["owner"], thumb_rep)
          end
          result << f_obj
        end
        result
      end

      def decode_work_type(obj)
        if obj["type"] =~ WORK_TYPE_WITH_PREFIX_PATTERN
          return "GenericWork" if $2.nil?
          $2
        else
          # this will return nil if key t does not exist
          work_type = obj["type"].downcase
          WORK_TYPES[work_type]
        end
      end

      def properties_ds(owner, representative=nil)
        s = %Q{<fields>
<depositor>batch_ingest</depositor>
<owner>#{owner}</owner>
}
        s += "<representative>#{representative}</representative>\n" if representative
        s += "</fields>\n"
      end

      private

      def next_label
        "$(pid--#{@seq})".tap { |_| @seq += 1 }
      end
    end
  end
end
