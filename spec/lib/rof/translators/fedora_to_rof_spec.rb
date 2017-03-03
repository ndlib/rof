require 'spec_helper'

RSpec.describe ROF::Translators::FedoraToRof do
  it 'handles embargo presence or absence' do
    rights_tests = [
      ['<embargo> <human/> <machine> <date>2017-08-01</date> </machine> </embargo>', true],
      ['<embargo> <human/> <machine> <date></date> </machine> </embargo>', false],
      ['<embargo> <human/> <machine/> </embargo>', false]
    ]

    rights_tests.each do |this_test|
      xml_doc = REXML::Document.new(this_test[0])
      root = xml_doc.root
      rights = described_class.has_embargo_date(root)
      expect(rights).to eq(this_test[1])
    end
  end
end
