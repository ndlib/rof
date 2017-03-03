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
    pid = 'und:dev0012829m'
    config = {}
    fedora = {}
    fedora[:url] = 'http://localhost:8080/fedora'
    fedora[:user] = 'fedoraAdmin'
    fedora[:password] = 'fedoraAdmin'
    VCR.use_cassette("fedora_to_rof1") do
      outfile = double(close: true, write: true)
      described_class.run([pid], fedora, outfile, config)
      expect(outfile).to have_received(:write).with(JSON.pretty_generate(expected_output))
      # fedora_data =  ROF::Translators::FedoraToRof.GetFromFedora(pid, fedora, config)
      # expect(fedora_data).to eq(expected_output)
    end
  end
end
