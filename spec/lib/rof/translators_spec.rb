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
  end
end
