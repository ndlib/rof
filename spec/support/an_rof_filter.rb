RSpec.shared_examples 'an ROF::Filter' do
  before do
    raise 'valid_options must be set with `let(:valid_options)`' unless
      defined? valid_options
  end

  subject { described_class.new(valid_options) }

  it { is_expected.to respond_to(:process).with(1).arguments }
end
