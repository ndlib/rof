module ROF
  # A placeholder implementation for an ROF::Filter.
  # @see ROF::Filters
  class Filter
    # @param [Hash] options - a hash with symbol keys; used to configure the instantiation of the filter
    def initialize(options = {})
    end

    # Performs operations on the given obj_list. This can be things like:
    #
    # * Adding new keys to the inner Hash
    # * Converting placeholder values with calculated values (@see ROF::Filters::Label)
    # * Other changes
    #
    # @param [Array<Hash>] obj_list - An Array of Hash objects
    # @return [Array<Hash>] a changed version of the given
    def process(obj_list)
      raise NotImplementedError
    end
  end
end
