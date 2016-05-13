require 'spec_helper'

module ROF
  describe "Ingest" do
    it "requires a fobject" do
      item = {"type" => "not fobject"}
      expect {ROF.Ingest(item)}.to raise_error(ROF::NotFobjectError)
    end
    it "requires a pid" do
      item = {"type" => "fobject"}
      expect {ROF.Ingest(item)}.to raise_error(ROF::MissingPidError)
    end
    it "disallows both id and pid" do
      item = {"type" => "fobject", "id" => '1', "pid" => '1'}
      expect {ROF.Ingest(item)}.to raise_error(ROF::TooManyIdentitiesError)
    end
    it "rejects two ways of giving a datastream" do
      item = {"type" => "fobject",
              "pid" => "test:1",
              "content" => "hello",
              "content-file" => "filename.txt"
      }
      expect {ROF.Ingest(item)}.to raise_error(ROF::SourceError)
    end
    it "uploads datastreams with apropos metadata" do
      item = {"type" => "fobject",
              "pid" => "test:1",
              "af-model" => "GenericFile",
              "content" => "jello",
              "content-meta" => {"label" => "test stream 1",
                                 "mime-type" => "application/jello"},
              "other-meta" => {"label" => "test stream 2"},
      }
      expect(ROF.Ingest(item)).to eq(["content", "other"])
    end

    it "treats id as a surrogate for pid when pid is missing" do
      item = {"type" => "fobject",
              "id" => "test:1",
              "af-model" => "GenericFile",
              "content" => "jello",
              "content-meta" => {"label" => "test stream 1",
                                 "mime-type" => "application/jello"},
              "other-meta" => {"label" => "test stream 2"},
      }
      expect(ROF.Ingest(item)).to eq(["content", "other"])
    end

    it "raises an error if content is not a string" do
      item = {"type" => "fobject",
              "id" => "test:1",
              "af-model" => "GenericFile",
              "content" => ["list", "of", "items"]
      }
      expect {ROF.Ingest(item)}.to raise_error(ROF::SourceError)
    end

    it "ignores null data streams" do
      item = {"type" => "fobject",
              "id" => "test:1",
              "af-model" => "GenericFile",
              "content" => nil
      }
      expect(ROF.Ingest(item)).to eq(["content"])
    end

    describe "RDF Metadata" do
      it "loads JSON-LD" do
        item = {"pid" => "test:1",
          "metadata" => {
            "@context" => {
              "dc" => "http://purl.org/dc/terms/",
            },
            "dc:title" => "Hello Z",
          }
        }
        s = ROF.ingest_ld_metadata(item, nil)
        expect(s).to eq %(<info:fedora/test:1> <http://purl.org/dc/terms/title> "Hello Z" .\n)
      end
    end
    describe "decoding rights metadata" do
      it "formats people and groups" do
        s = ROF.format_rights_section("qwerty", "alice", ["bob", "carol"])
        expect(s).to eq <<-EOS
  <access type="qwerty">
    <human/>
    <machine>
      <person>alice</person>
      <group>bob</group>
      <group>carol</group>
    </machine>
  </access>
EOS
      end
      it "handles no people or groups" do
        s = ROF.format_rights_section("qwerty", nil, nil)
        expect(s).to eq <<-EOS
  <access type="qwerty">
    <human/>
    <machine/>
  </access>
EOS
      end

      it "formats rights metadata correctly" do
        item = {
          "rights" => {
            "read-groups" => ["public"],
            "edit" => ["batch_user"],
          }
        }
        s = ROF.ingest_rights_metadata(item, nil)
        expect(s).to eq <<-EOS
<rightsMetadata xmlns="http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1" version="0.1">
  <copyright>
    <human type="title"/>
    <human type="description"/>
    <machine type="uri"/>
  </copyright>
  <access type="discover">
    <human/>
    <machine/>
  </access>
  <access type="read">
    <human/>
    <machine>
      <group>public</group>
    </machine>
  </access>
  <access type="edit">
    <human/>
    <machine>
      <person>batch_user</person>
    </machine>
  </access>
  <embargo>
    <human/>
    <machine/>
  </embargo>
</rightsMetadata>
EOS
      end
    end
  end

  describe "file_searching" do
    it "raises an error on missing files" do
      expect {ROF.find_file_and_open("file.txt",[],"r")}.to raise_error(Errno::ENOENT)
    end
  end
end
