require 'rof/translators/csv_to_rof'
require 'rof/translators/fedora_to_rof'
require 'rof/translators/osf_to_rof'

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
      CsvToRof.call(csv_contents)
    end

    # @api public
    #
    # Write to the output file an ROF JSON document
    #
    # @param pids [Array] Fedora PIDs
    # @param fedora [nil, Hash] Hash with connection information (e.g. URL, User)
    # @param outfile [String, (#write, #close)] A String that is interpretted as a path to a file. Else an IO object responding to #write and #close
    # @param config [Hash]
    # @return Void
    def self.fedora_to_rof(pids, fedora = nil, outfile = STDOUT, config = {})
      FedoraToRof.call(pids, fedora, outfile, config)
    end
  end
end
