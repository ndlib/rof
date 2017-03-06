require 'spec_helper'
require 'rof/translator'

module ROF
  RSpec.describe Translator do
    let(:input) { double }
    let(:config) { double }
    describe '.call' do
      subject { described_class.call(input, config) }
      it 'is an abstract method' do
        expect { subject }.to raise_error(NotImplementedError)
      end
    end
  end
end
