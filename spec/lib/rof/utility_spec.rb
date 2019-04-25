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
    describe 'next_label' do
       let(:id) { util.next_label}

       it 'assigns initial label' do
         expect(id).to eq '$(pid--0)'
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

    describe 'decode_work_type' do

      context 'decode article' do
	subject { util.decode_work_type({'type' => 'article'})  }
	it { is_expected.to eq('Article')}
      end

      context 'decode dataset' do
	subject { util.decode_work_type({'type' => 'dataset'})  }
	it { is_expected.to eq('Dataset')}
      end

      context 'decode document' do
	subject { util.decode_work_type({'type' => 'document'})  }
	it { is_expected.to eq('Document')}
      end

      context 'decode etd' do
	subject { util.decode_work_type({'type' => 'etd'})  }
	it { is_expected.to eq('Etd')}
      end

      context 'test downcase etd' do
	subject { util.decode_work_type({'type' => 'ETD'})  }
	it { is_expected.to eq('Etd')}
      end

      context 'test image' do
	subject { util.decode_work_type({'type' => 'image'})  }
	it { is_expected.to eq('Image')}
      end
    end
  end
end
