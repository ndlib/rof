Dir.glob(File.expand_path('../filters/*.rb', __FILE__)).each do |filename|
  require filename
end

module ROF
  # A container class for all ROF filters. What is an ROF filter? @see ROF::Filters.for
  # @see ROF::Filter for abstract definition
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
      "access-to-relsext" => ROF::Filters::AccessToRelsext
    }
    # @api public
    #
    # @param [String] filter_name - the named filter you want to instantiate
    # @param [Hash] options - a hash (with symbol keys) that is used for configuring the instantiating of the filter
    # @return [ROF::Filter]
    # @raise ROF::Filters::UnknownFilterError if the given filter name is not registered
    # @see ./spec/support/an_rof_filter.rb
    # @see ROF::Filter
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
