require 'spec_helper'

module ROF
  module Ingesters
    describe RelsExtIngester do
      let(:models) { ["info:fedora/afmodel:Shoe"] }
      let(:item) {
        { "pid" => '1234', "rels-ext" => { "isPartOf" => ["vecnet:d217qs82g"] } }
      }
      let(:fedora_document) { nil }
      let(:expected_content) { "<?xml version='1.0' encoding='utf-8' ?>\n<rdf:RDF xmlns:ns0='info:fedora/fedora-system:def/model#' xmlns:ns1='info:fedora/fedora-system:def/relations-external#' xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'>\n  <rdf:Description rdf:about='info:fedora/1234'>\n    <ns0:hasModel rdf:resource='info:fedora/afmodel:Shoe' />\n    <ns1:isPartOf rdf:resource='info:fedora/vecnet:d217qs82g' />\n  </rdf:Description>\n</rdf:RDF>\n" }

      subject { described_class.new(models: models, item: item, fedora_document: fedora_document) }

      context 'without a fedora document' do
        its(:call) { should be_equivalent_to(expected_content) }
      end

      context 'with a fedora document' do
        let(:fedora_document) { double }
        let(:rels_ext) { double }
        it 'should save the document' do
          expect(fedora_document).to receive(:[]).with('RELS-EXT').and_return(rels_ext)
          expect(rels_ext).to receive(:content=).with(be_equivalent_to(expected_content))
          expect(rels_ext).to receive(:mimeType=).with("application/rdf+xml")
          expect(rels_ext).to receive(:save)
          subject.call
        end
      end

      context 'it supports other namespaces' do
        let(:item) {
          { "pid" => '1234', "rels-ext" => {
              "@context" => { "ex" => "http://example.com/" },
              "isPartOf" => ["vecnet:d217qs82g", "vecnet:123"],
              "ex:hasAccessCopy" => ["vecnet:234"]
            }
          }
        }
        let(:expected_content) {
%Q{<?xml version='1.0' encoding='utf-8' ?>
<rdf:RDF xmlns:ns0='http://example.com/' xmlns:ns1='info:fedora/fedora-system:def/model#' xmlns:ns2='info:fedora/fedora-system:def/relations-external#' xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'>
  <rdf:Description rdf:about='info:fedora/1234'>
    <ns0:hasAccessCopy rdf:resource='info:fedora/vecnet:234' />
    <ns1:hasModel rdf:resource='info:fedora/afmodel:Shoe' />
    <ns2:isPartOf rdf:resource='info:fedora/vecnet:d217qs82g' />
     <ns2:isPartOf rdf:resource='info:fedora/vecnet:123' />
  </rdf:Description>
</rdf:RDF>\n} }
        let(:fedora_document) { double }
        let(:rels_ext) { double }
        it 'should save the document' do
          expect(fedora_document).to receive(:[]).with('RELS-EXT').and_return(rels_ext)
          expect(rels_ext).to receive(:content=).with(be_equivalent_to(expected_content))
          expect(rels_ext).to receive(:mimeType=).with("application/rdf+xml")
          expect(rels_ext).to receive(:save)
          subject.call
        end
      end

      context 'it handles nested objects' do
        let(:item) {
            { "pid" => 'abc:1234',
              "rels-ext" => {
                "isMemberOf" => { "@id" => "xyz:789" }
            }}
        }

        let(:expected_content) {
%Q{
<?xml version='1.0' encoding='utf-8' ?>
<rdf:RDF xmlns:ns0='info:fedora/fedora-system:def/model#' xmlns:ns1='info:fedora/fedora-system:def/relations-external#' xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'>
  <rdf:Description rdf:about='info:fedora/abc:1234'>
    <ns0:hasModel rdf:resource='info:fedora/afmodel:Shoe' />
    <ns1:isMemberOf rdf:resource='info:fedora/xyz:789' />
  </rdf:Description>
</rdf:RDF>
}
        }

        its(:call) { should be_equivalent_to(expected_content) }
      end
    end
  end
end
