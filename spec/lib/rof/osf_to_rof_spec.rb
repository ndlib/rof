require 'spec_helper'

RSpec.describe ROF::OsfToRof do
  it "converts  an OSF Archive tar,gz to an ROF", memfs: true do
    #Test file dirs
    test_dir = Dir.mktmpdir('FROM_OSF')
    ttl_dir = FileUtils.mkdir_p(File.join(test_dir, 'b6psa/data/obj/root')) 

    # tar and ttl files
    tar_file = File.join(test_dir, 'b6psa.tar.gz')
    proj_ttl_file = File.join(ttl_dir, 'b6psa.ttl')
    user_ttl_file = File.join(ttl_dir, 'qpru8.ttl')

    config = { 'package_dir' => "#{test_dir}" }
    osf_project = {
      "project_identifier" => "b6psa",
      "administrative_unit" => "Library",
      "owner" => "msuhovec",
      "affiliation" => "OddFellows Local 151",
      "status" => "submitted",
    }

    expected_rof = [{"owner"=>"msuhovec",
                     "type"=>"OsfArchive",
                     "rights"=>{"read-groups"=>["public"]},
                     "rels-ext"=> {"@context"=> {"@vocab"=>"info:fedora/fedora-system:def/relations-external#",
                                   "fedora-model"=>"info:fedora/fedora-system:def/model#",
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
                                                 "mrel"=>"http://id.loc.gov/vocabulary/relators/",
                                                 "nd"=>"https://library.nd.edu/ns/terms/",
                                                 "rdfs"=>"http://www.w3.org/2000/01/rdf-schema#",
                                                 "vracore"=>"http://purl.org/vra/",
                                                 "dc:dateSubmitted"=>{"@type"=>"http://www.w3.org/2001/XMLSchema#date"},
                                                 "dc:created"=>{"@type"=>"http://www.w3.org/2001/XMLSchema#date"},
                                                 "dc:modified"=>{"@type"=>"http://www.w3.org/2001/XMLSchema#date"}},
                                                 "dc:created"=>"2016-09-06Z",
                                                 "dc:title"=>"OSFNonInstProj1",
                                                 "dc:description"=>"",
                                                 "dc:subject"=>"",
                                                 "dc:source"=>"https://osf.io/b6psa",
                                                 "dc:creator#adminstrative_unit"=>"Library",
                                                 "dc:creator#affiliation"=>"OddFellows Local 151",
                                                 "dc:creator"=>["Mark Suhovecky"]},
                     "files"=>["b6psa.tar.gz"]}]

    FileUtils.cp('spec/fixtures/osf/b6psa.tar.gz', tar_file)

    begin
      expect(File.exists?(proj_ttl_file)).to be false
      expect(File.exists?(user_ttl_file)).to be false

      rof = ROF::OsfToRof.osf_to_rof(config, osf_project)

      expect(rof).to eq( expected_rof )

      # ingested history should be created
      expect(File.exists?(proj_ttl_file)).to be true
      expect(File.exists?(user_ttl_file)).to be true
    ensure
      # remove the directory.
      FileUtils.remove_entry test_dir
    end
  end
end
