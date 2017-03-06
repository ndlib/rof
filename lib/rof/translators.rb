Dir.glob(File.expand_path('../translators/*.rb', __FILE__)).each do |filename|
  require filename
end

module ROF
  # A namespace for organizing translating classes. A translating class is responsible for
  # converting from one format to another format (e.g. CSV to ROF).
  #
  # @see ROF::Translator
  # @see ROF::Translators::CsvToRof
  # @see ROF::Translators::FedoraToRof
  # @see ROF::Translators::OsfToRof
  module Translators
    # @api public
    # @param [String] csv_contents - in the form of a CSV
    # @param [Hash] config - Hash with symbols for keys
    # @return [Hash] in ROF format
    # @see ROF::Translators::CsvToRof for full details
    def self.csv_to_rof(csv_contents, config = {})
      CsvToRof.call(csv_contents, config)
    end
  end
end
