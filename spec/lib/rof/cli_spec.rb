require 'spec_helper'
require 'stringio'

describe ROF::CLI do
  describe '.ingest_array' do
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

  describe '.osf_to_rof' do
    let(:outfile) { double(write: true) }
    let(:data_from_file) { [:data_from_file] }
    let(:rof_data) { [{ "rof" => "true" }] }
    it 'loads the JSON file, calls the translator then writes the output as JSON' do
      config = { 'project_file' => File.join(GEM_ROOT, 'spec/fixtures/for_utility_load_items_from_json_file/single_item.json') }
      expect(ROF::Utility).to receive(:load_items_from_json_file).with(config.fetch('project_file'), outfile).and_return(data_from_file)
      expect(ROF::Translators::OsfToRof).to receive(:call).with(config, data_from_file[0]).and_return(rof_data)
      described_class.osf_to_rof(config, outfile)
      expect(outfile).to have_received(:write).with(JSON.pretty_generate(rof_data))
    end
  end
end
