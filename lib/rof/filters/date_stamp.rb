require 'date'

module ROF
  module Filters
    # add a metadata setting the upload date to be today, provided it
    # doesn't already exist
    class DateStamp
      def initialize(date=nil)
        @today = date || Date::today
        @today_s = if @today.is_a?(Date)
                     @today.strftime('%FZ')
                   else
                     @today.to_s
                   end
      end

      def process(obj_list)
        obj_list.map! do |obj|
          if obj["metadata"].nil?
            obj["metadata"] = {
              "@context" => ROF::RdfContext
            }
          end
          if obj["metadata"]["dc:dateSubmitted"].nil?
            obj["metadata"]["dc:dateSubmitted"] = @today_s
          end
          obj
        end
      end
    end
  end
end
