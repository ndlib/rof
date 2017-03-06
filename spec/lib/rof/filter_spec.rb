require 'spec_helper'

module ROF
  RSpec.describe Filter do
    subject { described_class.new }
    it 'defines an abstract #process method' do
      expect { subject.process({}) }.to raise_error(NotImplementedError)
    end
  end
end
