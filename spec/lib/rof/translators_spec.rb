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
  end
end
