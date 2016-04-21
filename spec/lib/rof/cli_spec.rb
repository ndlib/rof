require 'spec_helper'
require 'stringio'
require 'vcr'

fedora_to_rof1_data = '{"pid":"und:dev0012829m","type":"fobject","af-model":"GenericFile","rels-ext":{"hasModel":["GenericFile"],"isPartOf":["dev00128288"]},"rights":{"read-groups":["registered"],"edit":["dbrower"]},"properties":"<fields>\n<depositor>batch_ingest</depositor>\n<owner>dbrower</owner>\n</fields>\n","properties-meta":"text/xml","content-meta":{"label":"bonnie+chauncey","mime_type":"application/octet-stream","URL":"bendo:14000/item/dev0012826k/bonnie+chauncey"},"metadata":{"@context":{"dc":"http://purl.org/dc/terms/","foaf":"http://xmlns.com/foaf/0.1/","rdfs":"http://www.w3.org/2000/01/rdf-schema#","dc:dateSubmitted":{"@type":"http://www.w3.org/2001/XMLSchema#date"},"dc:modified":{"@type":"http://www.w3.org/2001/XMLSchema#date"}},"dc:dateSubmitted":"2016-04-12Z","dc:modified":"2016-04-12Z","dc:title":"bonnie+chauncey"},"bendo-item":"dev0012826k"}'

describe ROF::CLI do
  VCR.configure do |config|
    config.cassette_library_dir = "spec/fixtures/vcr_tests"
    config.hook_into :webmock
  end
    
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

    pid = 'und:dev0012829m'
    config = {}
    fedora = {}
    fedora[:url] = 'http://localhost:8080/fedora'
    fedora[:user] = 'fedoraAdmin'
    fedora[:password] = 'webmock'
    fedora_data = nil
    VCR.use_cassette("fedora_to_rof1") do
    	fedora_data =  ROF::FedoraToRof.GetFromFedora(pid, fedora, config)
    end
    output = JSON.generate(fedora_data)
    expect(output).to match(fedora_to_rof1_data)
  end
end
