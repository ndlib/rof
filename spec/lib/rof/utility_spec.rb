require 'spec_helper'

module ROF
  RSpec.describe Utility do
    let(:util) { described_class.new }

    describe 'prop_ds' do
      context 'set properties, representative is true' do
        subject { described_class.prop_ds(owner: 'msuhovec', representative: true) }
	it { is_expected.to match /<fields><depositor>batch_ingest<\/depositor>\n\t\t\t\t<owner>{:owner=>\"msuhovec\", :representative=>true}<\/owner><\/fields>\n/ }
      end

      context 'set properties, representative is false' do
        subject { described_class.prop_ds(owner: 'msuhovec', representative: false) }
	it { is_expected.to match /<fields><depositor>batch_ingest<\/depositor>\n\t\t\t\t<owner>{:owner=>\"msuhovec\", :representative=>false}<\/owner><\/fields>\n/ }
      end
    end
    describe 'next_label' do
       let(:id) { util.next_label}

       it 'assigns initial label' do
         id.should == '$(pid--0)'
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
