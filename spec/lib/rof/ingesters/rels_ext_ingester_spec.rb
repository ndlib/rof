require 'spec_helper'

module ROF
  module Ingesters
    describe RelsExtIngester do
      let(:models) { ["info:fedora/afmodel:Shoe"] }
      let(:item) {
        { "pid" => '1234', "rels-ext" => { "isPartOf" => ["vecnet:d217qs82g"] } }
      }
      let(:fedora_document) { nil }
      let(:expected_content) { "<rdf:RDF xmlns:ns0=\"info:fedora/fedora-system:def/model#\" xmlns:ns1=\"info:fedora/fedora-system:def/relations-external#\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"><rdf:Description rdf:about=\"info:fedora/1234\"><ns0:hasModel rdf:resource=\"info:fedora/afmodel:Shoe\"/><ns1:isPartOf rdf:resource=\"vecnet:d217qs82g\"/></rdf:Description></rdf:RDF>" }

      subject { described_class.new(models: models, item: item, fedora_document: fedora_document) }

      context 'without a fedora document' do
        its(:call) { should eq expected_content }
      end

      context 'with a fedora document' do
        let(:fedora_document) { double }
        let(:rels_ext) { double }
        it 'should save the document' do
          fedora_document.should_receive(:[]).with('RELS-EXT').and_return(rels_ext)
          rels_ext.should_receive(:content=).with(expected_content)
          rels_ext.should_receive(:mimeType=).with("application/rdf+xml")
          rels_ext.should_receive(:save)
          subject.call
        end
      end
    end
  end
end
