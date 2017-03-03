require 'rof/translators/csv_to_rof'
module ROF
  # A namespace for organizing translating classes. A translating class is responsible for
  # converting from one format to another format (e.g. CSV to ROF).
  #
  # @see ROF::Translators::CsvToRof
  module Translators
    # @api public
    # @param csv_contents [String] in the form of a CSV
    # @return [Hash] in ROF format
    # @see ROF::Translators::CsvToRof for full details
    def self.csv_to_rof(csv_contents)
      CsvToRof.run(csv_contents)
    end
  end
end
