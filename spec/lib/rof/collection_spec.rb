require 'spec_helper'

module ROF
  RSpec.describe Collection do
    let!(:util) { ROF::Utility.new }
    let!(:testobject1) { { 'owner' => 'rtillman', 'pid' => '$(first)'} } 
    let!(:testobject2) { { 'owner' => 'rtillman', 'rights' => { 'read-groups' => [ 'public' ], 'edit' => [ 'edit']}} } 
    let!(:testobject3) { { 'owner' => 'rtillman', "metadata" => { "dc:title" => "Extensive Reading in Japanese"} } }
    let!(:testobject4) { { 'owner' => 'rtillman', "files" => [ '/it_is_not_there'] } }

    describe 'set_required_fields' do
    let(:obj) { ROF::Collection.set_required_fields( testobject1, util) }
    let(:obj_rights) { ROF::Collection.set_required_fields( testobject2, util) }
    let(:obj_metadata) { ROF::Collection.set_required_fields( testobject3, util) }
      context 'type' do
	subject { obj['type'] }
	it { is_expected.to eq("fobject") }
      end
      context 'af-model' do
	subject { obj['af-model'] }
	it { is_expected.to eq("Collection") }
      end
      context 'rights' do
	subject { obj_rights['rights'] }
	it { is_expected.to eq({"read-groups"=>["public"], "edit"=>["edit"]}) }
      end
      context 'metadata' do
	subject { obj_metadata['metadata'] }
	it { is_expected.to eq({"dc:title"=>"Extensive Reading in Japanese"}) }
      end
      context 'pid' do
	subject { obj['pid'] }
	it { is_expected.to eq("$(first)") }
      end
      context 'properties' do
	subject { obj['properties'] }
	it { is_expected.to match /<fields><depositor>batch_ingest<\/depositor>\n\t\t\t\t<owner>rtillman<\/owner><\/fields>\n/ }
      end
      context 'properties--meta' do
	subject { obj['properties-meta'] }
	it { is_expected.to eq({ 'mime-type' => 'text/xml' }) }
      end
    end
    describe 'mk_dest_img_name' do
      context 'with file extension' do
	subject { ROF::Collection.mk_dest_img_name('/opt/data/und:12345/flashcrowd.jpg', '-thumb') }
	it { is_expected.to eq("/opt/data/und:12345/flashcrowd-thumb.jpg") }
      end
      context 'without file extension' do
	subject { ROF::Collection.mk_dest_img_name('/opt/data/und:12345/flashcrowd', '-launch') }
	it { is_expected.to eq("/opt/data/und:12345/flashcrowd-launch") }
      end
    end
    describe 'make_images' do
      it 'raises error with non-existent file' do
	expect { ROF::Collection.make_images({}, testobject4, util)}.to raise_error(ROF::Collection::NoFile) 
      end
    end
    describe 'find_file_mime' do
      context 'jpg' do
	subject { ROF::Collection.find_file_mime('/opt/data/und:12345/flashcrowd.jpg') }
	it { is_expected.to eq("image/jpeg") }
      end
      context 'JPG' do
	subject { ROF::Collection.find_file_mime('und:12345/flashcrowd.JPG') }
	it { is_expected.to eq("image/jpeg") }
      end
      context 'GIF' do
	subject { ROF::Collection.find_file_mime('und:12345/flashcrowd.GIF') }
	it { is_expected.to eq("image/gif") }
      end
      context 'gif' do
	subject { ROF::Collection.find_file_mime('/und:12345/flashcrowd.gif') }
	it { is_expected.to eq("image/gif") }
      end
      context 'png' do
	subject { ROF::Collection.find_file_mime('death_of_middle_class.png') }
	it { is_expected.to eq("image/png") }
      end
      context 'PNG' do
	subject { ROF::Collection.find_file_mime('death_of_middle_class.PNG') }
	it { is_expected.to eq("image/png") }
      end
    end
  end
end
