module ROF
  # A translator is responsible for converting the input into the given output.
  # The input and output need not be the same type (e.g. CSV to Hash)
  #
  # @todo This is a work in progress; I will be normalizing the .call behavior.
  #
  # @see ROF::Translators::CsvToRof
  # @see ROF::Translators::FedoraToRof
  # @see ROF::Translators::OsfToRof
  class Translator
    # @param [Object] input - the thing that will be processed
    # @param [Hash] config - a Hash with symbol keys
    # @return [Hash] often times a Hash that can be serialized into JSON
    def self.call(input, config = {})
      raise NotImplementedError
    end
  end
end
