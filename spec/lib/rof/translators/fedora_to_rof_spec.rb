require 'spec_helper'

RSpec.describe ROF::Translators::FedoraToRof do
  let(:outfile) { double(close: true, write: true) }
  let(:pid) { 'und:dev0012829m' }
  let(:config) { { fedora_connection_information: fedora_connection_information } }
  let(:fedora_connection_information) { { url: 'http://localhost:8080/fedora', user: 'fedoraAdmin', password: 'fedoraAdmin' } }

  it 'will fail to initialize without a valid fedora connection' do
    allow(Rubydora).to receive(:connect).with(fedora_connection_information).and_raise('Woof')
    expect { described_class.new([pid], config) }.to raise_error('Woof')
  end

  describe '.call' do
    it "retrieves a fedora object and converts it to ROF" do
      expected_output = [{
        "pid" => "und:dev0012829m",
        "type" => "fobject",
        "af-model" => "GenericFile",
        "rels-ext" => {
          "@context"=> ROF::RelsExtRefContext,
          "@id" => "und:dev0012829m",
          "isPartOf"=> "und:dev00128288"
        },
        "rights" => {
          "read-groups" => ["registered"],
          "edit" => ["dbrower"]
        },
        "properties-meta" => {"mime-type" => "text/xml"},
        "properties" => "<fields>\n<depositor>batch_ingest</depositor>\n<owner>dbrower</owner>\n</fields>\n",
        "content-meta" => {"label"=>"bonnie+chauncey", "mime-type"=>"application/octet-stream", "URL"=>"http://libvirt9.library.nd.edu:14000/item/dev0012826k/bonnie+chauncey"},
        "metadata" => {
          "@context"=> {
             "bibo"=>"http://purl.org/ontology/bibo/",
             "dc"=>"http://purl.org/dc/terms/",
             "ebucore"=>"http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#",
             "foaf"=>"http://xmlns.com/foaf/0.1/",
             'hydramata-rel' => 'http://projecthydra.org/ns/relations#',
             "mrel"=>"http://id.loc.gov/vocabulary/relators/",
             "ms" => 'http://www.ndltd.org/standards/metadata/etdms/1.1/',
             "nd"=>"https://library.nd.edu/ns/terms/",
             "rdfs"=>"http://www.w3.org/2000/01/rdf-schema#",
             'ths' => 'http://id.loc.gov/vocabulary/relators/',
             "vracore"=>"http://purl.org/vra/",
             "pav"=>"http://purl.org/pav/",
             "dc:dateSubmitted" => {"@type" => "http://www.w3.org/2001/XMLSchema#date"},
             "dc:created"=>{"@type"=>"http://www.w3.org/2001/XMLSchema#date"},
             "dc:modified" => {"@type" => "http://www.w3.org/2001/XMLSchema#date"}
          },
          "@id" => "info:fedora/und:dev0012829m",
          "dc:dateSubmitted" => "2016-04-12Z",
          "dc:modified" => "2016-04-12Z",
          "dc:title" => "bonnie+chauncey"
        },
        "bendo-item" => "dev0012826k",
        "characterization-meta" => {"mime-type"=>"text/xml"},
        "thumbnail-meta" => {"label"=>"File Datastream", "mime-type"=>"image/png"},
      }]
      VCR.use_cassette("fedora_to_rof1") do
        expect(described_class.call([pid], config)).to eq(expected_output)
      end
    end
  end
end
