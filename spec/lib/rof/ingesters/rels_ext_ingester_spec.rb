require 'spec_helper'

module ROF
  module Ingesters
    describe RelsExtIngester do
      let(:models) { ["info:fedora/afmodel:Shoe"] }
      let(:item) {
        { "pid" => '1234', "rels-ext" => { "isPartOf" => ["vecnet:d217qs82g"] } }
      }
      subject { described_class.new(models: models, item: item, ) }

      its(:call) { should eq "<rdf:RDF xmlns:ns0=\"info:fedora/fedora-system:def/model#\" xmlns:ns1=\"info:fedora/fedora-system:def/relations-external#\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"><rdf:Description rdf:about=\"info:fedora/1234\"><ns0:hasModel rdf:resource=\"info:fedora/afmodel:Shoe\"/><ns1:isPartOf rdf:resource=\"vecnet:d217qs82g\"/></rdf:Description></rdf:RDF>" }
    end
  end
end
