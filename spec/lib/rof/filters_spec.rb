require 'spec_helper'

module ROF
  RSpec.describe Filters do
    describe '.for' do
      it 'raises an exception when one is not registered' do
        expect { described_class.for('obviously-not-valid') }.to raise_error(described_class::UnknownFilterError)
      end
      it 'instantiates a valid filter' do
        expect(described_class.for('datestamp')).to be_a(ROF::Filters::DateStamp)
      end
    end
  end
end
