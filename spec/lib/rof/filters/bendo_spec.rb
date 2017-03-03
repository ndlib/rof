require 'spec_helper'
require 'rof/filters/bendo'
require 'support/an_rof_filter'

RSpec.describe ROF::Filters::Bendo do
  it_behaves_like "an ROF::Filter"
  let(:bendo){ nil }
  let(:valid_options) { { bendo_info: bendo} }

  it 'requires bendo_info to initialize' do
    expect { described_class.new({}) }.to raise_error(KeyError)
  end
  describe '#process' do
    subject { described_class.new(bendo_info: bendo).process(original_object_list) }
    let(:original_object_list) do
      [
        { "content-meta" => { "URL" => "bendo:/item/12345/a/file.txt" } },
        { "not_gonna_change" => { "URL" => "bendo:/item/12345/a/file.txt" } },
        { "content-meta" => { "URL" => "somewhere:/item/12345/a/file.txt" } }
      ]
    end

    context 'if bendo is set' do
      let(:bendo) { 'http://bendo.host' }
      it 'will replace "bendo:" with the given bendo string' do
        expected_object_list = [
          { "content-meta" => { "URL" => "#{bendo}/item/12345/a/file.txt" } },
          { "not_gonna_change" => { "URL" => "bendo:/item/12345/a/file.txt" } },
          { "content-meta" => { "URL" => "somewhere:/item/12345/a/file.txt" } }
        ]
        expect(subject).to eq(expected_object_list)
      end
    end

    context 'if bendo is not set' do
      let(:bendo) { nil }
      it 'will not replace "bendo:" in any of the data entries' do
        expect(subject).to eq(original_object_list)
      end
    end
  end
end
