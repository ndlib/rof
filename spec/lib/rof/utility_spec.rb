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

      context 'decode collection' do
	subject { util.decode_work_type({'type' => 'collection'})  }
	it { is_expected.to eq('Collection')}
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
