require 'spec_helper'
require 'stringio'

describe ROF::CLI do
  it "ingests an array of items" do
    items = [{"pid" => "test:1",
              "type" => "fobject"},
             {"pid" => "test:2",
              "type" => "fobject"}]
    output = StringIO.new
    ROF::CLI.ingest_array(items, [], output)
    expect(output.string).to match(/1\. Verifying test:1 \.\.\.ok\..*\n2\. Verifying test:2 \.\.\.ok\./)
  end

  it "retrieves a fedora object and converts it to ROF" do
    expected_output = {
      "pid" => "und:dev0012829m",
      "type" => "fobject",
      "af-model" => "GenericFile",
      "rels-ext" => {
        "@context"=> ROF::RelsExtRefContext,
        "isPartOf"=> "und:dev00128288"
      },
      "rights" => {
        "read-groups" => ["registered"],
        "edit" => ["dbrower"]
      },
      "properties" => "<fields>\n<depositor>batch_ingest</depositor>\n<owner>dbrower</owner>\n</fields>\n",
      "properties-meta" => {"mime-type" => "text/xml"},
      "content-meta" => {
        "label" => "bonnie+chauncey",
        "mime_type" => "application/octet-stream",
        "URL" => "bendo:14000/item/dev0012826k/bonnie+chauncey"
      },
      "metadata" => {
        "@context" => {
          "bibo"=>"http://purl.org/ontology/bibo/",
          "dc"=>"http://purl.org/dc/terms/",
          "ebucore"=>"http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#",
          "foaf"=>"http://xmlns.com/foaf/0.1/",
          "mrel"=>"http://id.loc.gov/vocabulary/relators/",
          "nd"=>"https://library.nd.edu/ns/terms/",
          "rdfs"=>"http://www.w3.org/2000/01/rdf-schema#",
          "vracore"=>"http://purl.org/vra/",
          "dc:dateSubmitted" => {"@type" => "http://www.w3.org/2001/XMLSchema#date"},
          "dc:created"=>{"@type"=>"http://www.w3.org/2001/XMLSchema#date"},
          "dc:modified" => {"@type" => "http://www.w3.org/2001/XMLSchema#date"}
        },
        "dc:dateSubmitted" => "2016-04-12Z",
        "dc:modified" => "2016-04-12Z",
        "dc:title" => "bonnie+chauncey"
      },
      "bendo-item" => "dev0012826k",
      "characterization-meta" => {"mime-type"=>"text/xml"},
      "content-meta" => {"label"=>"bonnie+chauncey", "mime-type"=>"application/octet-stream", "URL"=>"http://libvirt9.library.nd.edu:14000/item/dev0012826k/bonnie+chauncey"},
      "thumbnail-meta" => {"label"=>"File Datastream", "mime-type"=>"image/png"},
    }
    pid = 'und:dev0012829m'
    config = {}
    fedora = {}
    fedora[:url] = 'http://localhost:8080/fedora'
    fedora[:user] = 'fedoraAdmin'
    fedora[:password] = 'fedoraAdmin'
    VCR.use_cassette("fedora_to_rof1") do
      fedora_data =  ROF::FedoraToRof.GetFromFedora(pid, fedora, config)
      expect(fedora_data).to eq(expected_output)
    end
  end
end
