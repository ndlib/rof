require 'date'

module ROF
  module Filters
    # Set the upload date to be the date given, provided it doesn't already exist.
    # Also set the date modified to be the date given.
    # If not given, the date used defaults to the local time on the computer.
    class DateStamp
      def initialize(options = {})
        @today = options.fetch(:as_of) { Date::today }
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
          # only save the date submitted if it is not already present
          if obj["metadata"]["dc:dateSubmitted"].nil?
            obj["metadata"]["dc:dateSubmitted"] = @today_s
          end
          # always update the date modified
          obj["metadata"]["dc:modified"] = @today_s
          obj
        end
      end
    end
  end
end
