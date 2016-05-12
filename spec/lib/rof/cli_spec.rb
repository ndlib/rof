require 'spec_helper'
require 'stringio'
require 'vcr'

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
        "@context"=>{
          "@vocab"=>"info:fedora/fedora-system:def/relations-external#",
          "fedora-model"=>"info:fedora/fedora-system:def/model#",
          "hydra"=>"http://projecthydra.org/ns/relations#",
          "hasModel"=>{"@id"=>"fedora-model:hasModel", "@type"=>"@id"},
          "hasEditor"=>{"@id"=>"hydra:hasEditor", "@type"=>"@id"},
          "hasEditorGroup"=>{"@id"=>"hydra:hasEditorGroup", "@type"=>"@id"},
          "isPartOf"=>{"@type"=>"@id"}
        },
        "isPartOf"=>["und:dev00128288"]
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
          "dc" => "http://purl.org/dc/terms/",
          "foaf" => "http://xmlns.com/foaf/0.1/",
          "rdfs" => "http://www.w3.org/2000/01/rdf-schema#",
          "dc:dateSubmitted" => {"@type" => "http://www.w3.org/2001/XMLSchema#date"},
          "dc:modified" => {"@type" => "http://www.w3.org/2001/XMLSchema#date"}
        },
        "dc:dateSubmitted" => "2016-04-12Z",
        "dc:modified" => "2016-04-12Z",
        "dc:title" => "bonnie+chauncey"
      },
      "bendo-item" => "dev0012826k",
      "characterization-meta" => {"mime-type"=>"text/xml"},
      "content-meta" => {"label"=>"bonnie+chauncey", "mime-type"=>"application/octet-stream"},
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
      expect(fedora_data).to match(expected_output)
    end
  end
end
