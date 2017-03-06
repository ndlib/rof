require 'spec_helper'

module ROF
  RSpec.describe Translators do
    describe '.csv_to_rof' do
      it 'delegates to CsvToRof.call' do
        contents = double
        config = double
        expect(described_class::CsvToRof).to receive(:call).with(contents, config)
        described_class.csv_to_rof(contents, config)
      end
    end

    describe '.fedora_to_rof' do
      it 'delegates to FedoraToRof.call' do
        contents = double
        fedora = double
        outfile = double
        config = double
        expect(described_class::FedoraToRof).to receive(:call).with(contents, fedora, outfile, config)
        described_class.fedora_to_rof(contents, fedora, outfile, config)
      end
    end
  end
end
