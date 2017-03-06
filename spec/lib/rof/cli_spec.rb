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
    let(:config) { {} }
    let(:project_file) { File.join(GEM_ROOT, 'spec/fixtures/for_utility_load_items_from_json_file/single_item.json') }
    it 'loads the JSON file, calls the translator then writes the output as JSON' do
      expect(ROF::Utility).to receive(:load_items_from_json_file).with(project_file, outfile).and_return(data_from_file)
      expect(ROF::Translators::OsfToRof).to receive(:call).with(data_from_file[0], config).and_return(rof_data)
      described_class.osf_to_rof(project_file, config, outfile)
      expect(outfile).to have_received(:write).with(JSON.pretty_generate(rof_data))
    end
  end

  describe '.fedora_to_rof' do
    let(:outfile) { double(write: true) }
    let(:pids) { [1, 2, 3] }
    let(:rof_data) { [{ "rof" => "true" }] }
    let(:config) { {} }
    it 'calls the translator then writes the output as JSON' do
      expect(ROF::Translators::FedoraToRof).to receive(:call).with(pids, config).and_return(rof_data)
      described_class.fedora_to_rof(pids, config, outfile)
      expect(outfile).to have_received(:write).with(JSON.pretty_generate(rof_data))
    end
  end

  describe '.with_outfile_handling' do
    let(:writer) { double(close: true) }
    context 'when given a string' do
      let(:outfile) { '/hello/world' }
      it 'will open a file' do
        expect(File).to receive(:open).with('/hello/world', 'w').and_return(writer)
        expect {|b| described_class.with_outfile_handling(outfile, &b) }.to yield_with_args(writer)
        expect(writer).to have_received(:close)
      end
    end
    context 'when given nil' do
      let(:outfile) { nil }
      it 'will write to /dev/null' do
        expect(File).to receive(:open).with('/dev/null', 'w').and_return(writer)
        expect {|b| described_class.with_outfile_handling(outfile, &b) }.to yield_with_args(writer)
        expect(writer).to have_received(:close)
      end
    end
    context 'when given something else' do
      it 'will assume it is can be "written" to' do
        expect {|b| described_class.with_outfile_handling(writer, &b) }.to yield_with_args(writer)
        expect(writer).to have_received(:close)
      end
    end
  end
end
