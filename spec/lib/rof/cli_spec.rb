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
end
