require 'spec_helper'

RSpec.describe ROF::Translators::OsfToRof do
  #Test file dirs
  let(:test_dir) { Dir.mktmpdir('FROM_OSF') }
  let(:ttl_dir) { FileUtils.mkdir_p(File.join(test_dir, 'b6psa/data/obj/root')) }

  # tar and ttl files
  let(:tar_file) { File.join(test_dir, 'b6psa.tar.gz') }
  let(:proj_ttl_file) { File.join(ttl_dir, 'b6psa.ttl') }
  let(:user_ttl_file) { File.join(ttl_dir, 'qpru8.ttl') }

  let(:config) { { 'package_dir' => "#{test_dir}" } }
  let(:osf_project) do
    {
      "project_identifier" => "b6psa",
      "package_type" => "OSF Registration",
      "administrative_unit" => "Library",
      "owner" => "msuhovec",
      "affiliation" => "OddFellows Local 151",
      "status" => "submitted",
    }
  end
  around do |the_example|
    FileUtils.cp('spec/fixtures/osf/b6psa.tar.gz', tar_file)
    begin
      the_example.call
    ensure
      FileUtils.remove_entry test_dir
    end
  end

  it "converts  an OSF Registration tar,gz to an ROF", memfs: true do
    expected_rof = [{"owner"=>"msuhovec",
                     "type"=>"OsfArchive",
                     "rights"=>{"read-groups"=>["public"]},
                     "rels-ext"=> {"@context"=> {"@vocab"=>"info:fedora/fedora-system:def/relations-external#",
                                   "fedora-model"=>"info:fedora/fedora-system:def/model#",
                                   "pav"=>"http://purl.org/pav/",
                                   "hydra"=>"http://projecthydra.org/ns/relations#",
                                   "hasModel"=>{"@id"=>"fedora-model:hasModel", "@type"=>"@id"},
                                   "hasEditor"=>{"@id"=>"hydra:hasEditor", "@type"=>"@id"},
                                   "hasEditorGroup"=>{"@id"=>"hydra:hasEditorGroup", "@type"=>"@id"},
                                   "isPartOf"=>{"@type"=>"@id"},
                                   "isMemberOfCollection"=>{"@type"=>"@id"},
                                   "isEditorOf"=>{"@id"=>"hydra:isEditorOf", "@type"=>"@id"},
                                   "hasMember"=>{"@type"=>"@id"},
                                   "previousVersion"=>"http://purl.org/pav/previousVersion"}},
                     "metadata"=> {"@context"=> {"bibo"=>"http://purl.org/ontology/bibo/",
                                                 "dc"=>"http://purl.org/dc/terms/",
                                                 "ebucore"=>"http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#",
                                                 "foaf"=>"http://xmlns.com/foaf/0.1/",
                                                 'hydramata-rel' => 'http://projecthydra.org/ns/relations#',
                                                 "mrel"=>"http://id.loc.gov/vocabulary/relators/",
                                                 'ms' => 'http://www.ndltd.org/standards/metadata/etdms/1.1/',
                                                 "nd"=>"https://library.nd.edu/ns/terms/",
                                                 "rdfs"=>"http://www.w3.org/2000/01/rdf-schema#",
                                                 'ths' => 'http://id.loc.gov/vocabulary/relators/',
                                                 "vracore"=>"http://purl.org/vra/",
                                                 "pav"=>"http://purl.org/pav/",
                                                 "dc:dateSubmitted"=>{"@type"=>"http://www.w3.org/2001/XMLSchema#date"},
                                                 "dc:created"=>{"@type"=>"http://www.w3.org/2001/XMLSchema#date"},
                                                 "dc:modified"=>{"@type"=>"http://www.w3.org/2001/XMLSchema#date"}},
                                                 "dc:created"=>"2016-09-06Z",
                                                 "dc:title"=>"OSFNonInstProj1",
                                                 "dc:description"=>"",
                                                 "dc:subject"=>"",
                                                 "dc:source"=>"https://osf.io/b6psa",
						 "dc:type"=>"OSF Registration",
                                                 "dc:creator#adminstrative_unit"=>"Library",
                                                 "dc:creator#affiliation"=>"OddFellows Local 151",
                                                 "dc:creator"=>["Mark Suhovecky"],
                                                 "nd:osfProjectIdentifier"=>"ymt9w"},
                     "files"=>["b6psa.tar.gz"]}]
    expect(File.exists?(proj_ttl_file)).to be false
    expect(File.exists?(user_ttl_file)).to be false

    rof = ROF::Translators::OsfToRof.osf_to_rof(config, osf_project)

    expect(rof).to eq( expected_rof )

    # ingested history should be created
    expect(File.exists?(proj_ttl_file)).to be true
    expect(File.exists?(user_ttl_file)).to be true
  end

  describe 'RELS-EXT["pav:previousVersion"]' do
    let(:converter) { ROF::Translators::OsfToRof.new(config, osf_project, previous_pid_finder) }
    let(:pid_of_previous_version) { '1234' }
    describe 'when previous pid is found' do
      let(:previous_pid_finder) { double(call: pid_of_previous_version) }
      it 'will set rels-ext pav:previousVersion to the previous pid' do
        rof = converter.call
        rels_ext = rof[0].fetch('rels-ext')
        expect(rels_ext.fetch('pav:previousVersion')).to eq(pid_of_previous_version)
        expect(previous_pid_finder).to have_received(:call).with(converter.archive_type, converter.osf_project_identifier)
      end
    end
    describe 'when previous pid is NOT found' do
      let(:previous_pid_finder) { double(call: nil) }
      it 'will not set rels-ext pav:previousVersion to the previous pid' do
        rof = converter.call
        rels_ext = rof[0].fetch('rels-ext')
        expect { rels_ext.fetch('pav:previousVersion') }.to raise_error(KeyError)
        expect(previous_pid_finder).to have_received(:call).with(converter.archive_type, converter.osf_project_identifier)
      end
    end
  end
end
