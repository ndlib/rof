require 'spec_helper'

module ROF
  RSpec.describe Utility do
    let(:util) { described_class.new }

    describe 'prop_ds' do
      context 'set properties with representative' do
        subject { described_class.prop_ds('msuhovec', 'temp:1234') }
        it { is_expected.to eq "<fields><depositor>batch_ingest</depositor>\n<owner>msuhovec</owner>\n<representative>temp:1234</representative>\n</fields>\n" }
      end

      context 'set properties without representative' do
        subject { described_class.prop_ds('msuhovec') }
        it { is_expected.to eq "<fields><depositor>batch_ingest</depositor>\n<owner>msuhovec</owner>\n</fields>\n" }
      end
    end

    describe 'prop_ds_to_value' do
      context 'decode properties datastream' do
        subject { described_class.prop_ds_to_values("<fields><depositor>batch_ingest</depositor>\n<owner>msuhovec</owner>\n<representative>temp:1234</representative>\n</fields>\n") }
        it { is_expected.to eq({ owner: "msuhovec", representative: "temp:1234"}) }
      end
      context 'decode without representative' do
        subject { described_class.prop_ds_to_values("<fields><depositor>batch_ingest</depositor>\n<owner>msuhovec</owner>\n</fields>\n") }
        it { is_expected.to eq({ owner: "msuhovec", representative: nil}) }
      end
    end

    describe '.load_items_from_json_file' do
      let(:logger) { double(puts: true) }
      subject { described_class.load_items_from_json_file(filename, logger) }
      context 'with a parse error' do
        let(:filename) { File.join(GEM_ROOT, 'spec/fixtures/for_utility_load_items_from_json_file/parse_error.json') }
        it 'will log the error and abort' do
          expect(described_class).to receive(:exit!)
          subject
          expect(logger).to have_received(:puts).with(kind_of(String))
        end
      end
      context 'with a single item' do
        let(:filename) { File.join(GEM_ROOT, 'spec/fixtures/for_utility_load_items_from_json_file/single_item.json') }
        it 'will return an Array' do
          expect(described_class).not_to receive(:exit!)
          expect(subject).to eq([{ "hello" => "world" }])
          expect(logger).not_to have_received(:puts).with(kind_of(String))
        end
      end
      context 'with a multiple items' do
        let(:filename) { File.join(GEM_ROOT, 'spec/fixtures/for_utility_load_items_from_json_file/multiple_items.json') }
        it 'will return an Array' do
          expect(described_class).not_to receive(:exit!)
          expect(subject).to eq([{ "hello" => "world" }, { "good" => "bye" }])
          expect(logger).not_to have_received(:puts).with(kind_of(String))
        end
      end
    end

    describe '.has_embargo_date?' do
      it 'handles embargo presence or absence' do
        rights_tests = [
          ['<embargo> <human/> <machine> <date>2017-08-01</date> </machine> </embargo>', true],
          ['<embargo> <human/> <machine> <date></date> </machine> </embargo>', false],
          ['<embargo> <human/> <machine/> </embargo>', false]
        ]

        rights_tests.each do |this_test|
          xml_doc = REXML::Document.new(this_test[0])
          root = xml_doc.root
          rights = described_class.has_embargo_date?(root)
          expect(rights).to eq(this_test[1])
        end
      end
    end

    describe 'DoubleCaret' do
      test_cases = [
        ["no caret", "no caret"],
        ["no beginning caret ^^ here", "no beginning caret ^^ here"],
        ["^^name Peter", {"name" => "Peter"}],
        ["^^something-else can have ^single^ carets", {"something-else" => "can have ^single^ carets"}],
        ["^^first there^^second can^^third be many items^^fourth encoded",
          {"first" => "there", "second" => "can", "third" => "be many items", "fourth" => "encoded"}]
      ]

      it "decodes strings correctly" do
        test_cases.each do |this_test|
          result = described_class.DecodeDoubleCaret(this_test[0])
          expect(result).to eq(this_test[1])
        end
      end

      it "encodes strings correctly" do
        test_cases.each do |this_test|
          next if !this_test[1].is_a?(Hash)
          result = described_class.EncodeDoubleCaret(this_test[1])
          expect(result).to eq(this_test[0])
        end
      end
    end
  end
end
