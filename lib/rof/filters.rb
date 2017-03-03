Dir.glob(File.expand_path('../filters/*.rb', __FILE__)).each do |filename|
  require filename
end

module ROF
  module Filters
    class UnknownFilterError < RuntimeError
      def initialize(filter_name, available_filters)
        super(%(Unable to find filter "#{filter_name}". Available filter names are: #{available_filters.inspect}))
      end
    end
    AVAILABLE_FILTERS = {
      "bendo" => ROF::Filters::Bendo,
      "datestamp" => ROF::Filters::DateStamp,
      "file-to-url" => ROF::Filters::FileToUrl,
      "label" => ROF::Filters::Label,
      "work" => ROF::Filters::Work,
    }
    def self.for(filter_name, options = {})
      begin
        filter = AVAILABLE_FILTERS.fetch(filter_name)
      rescue KeyError
        raise UnknownFilterError.new(filter_name, AVAILABLE_FILTERS.keys)
      end
      filter.new(options)
    end
  end
end
