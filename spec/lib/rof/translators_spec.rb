require 'spec_helper'

module ROF
  RSpec.describe Translators do
    describe '.csv_to_rof' do
      it 'delegates to CsvToRof.run' do
        contents = double
        expect(described_class::CsvToRof).to receive(:run).with(contents)
        described_class.csv_to_rof(contents)
      end
    end

    describe '.fedora_to_rof' do
      it 'delegates to FedoraToRof.run' do
        contents = double
        fedora = double
        outfile = double
        config = double
        expect(described_class::FedoraToRof).to receive(:run).with(contents, fedora, outfile, config)
        described_class.fedora_to_rof(contents, fedora, outfile, config)
      end
    end
  end
end
