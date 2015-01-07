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

      class NoFile < RuntimeError
      end

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
      def process_one_work(input_obj)
        model = decode_work_type(input_obj)
        return [input_obj] if model.nil?

        main_obj = {
          "type" => "fobject",
          "af-model" => model,
          "pid" => input_obj.fetch("pid", next_label),
          "rights" => input_obj["rights"],
          "properties" => properties_ds(input_obj["owner"]),
          "properties-meta" => {
            "mime-type" => "text/xml"
          },
          "metadata" => input_obj["metadata"]
        }
        result = [main_obj]
        return result if input_obj["files"].nil?
        # make the first file be the representative thumbnail
        thumb_rep = nil
        input_obj["files"].each do |finfo|
          if finfo.is_a?(String)
            fname = finfo
            finfo = {"files" => [fname]}
          else
            fname = finfo["files"].first
            raise NoFile if fname.nil?
          end
          finfo["rights"] ||= input_obj["rights"]
          finfo["owner"] ||= input_obj["owner"]
          finfo["metadata"] ||= {
            "@context" => ROF::RdfContext
          }
          finfo["metadata"]["dc:title"] ||= fname
          mimetype = MIME::Types.of(fname)
          mimetype = mimetype.empty? ? "application/octet-stream" : mimetype.first.content_type
          f_obj = {
            "type" => "fobject",
            "af-model" => "GenericFile",
            "pid" => finfo["pid"],
            "rights" => finfo["rights"],
            "properties" => properties_ds(finfo["owner"]),
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
            "metadata" => finfo["metadata"]
          }
          f_obj.delete_if { |k,v| v.nil? }
          if thumb_rep.nil?
            thumb_rep = f_obj["pid"]
            if thumb_rep.nil?
              thumb_rep = next_label
              f_obj["pid"] = thumb_rep
            end
            main_obj["properties"] = properties_ds(input_obj["owner"], thumb_rep)
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
