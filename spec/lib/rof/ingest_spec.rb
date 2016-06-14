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
      expect(ROF.Ingest(item)).to eq(["rels-ext", "content", "other"])
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
      expect(ROF.Ingest(item)).to eq(["rels-ext", "content", "other"])
    end

    it "doesn't touch the rels ext if the model and rels-ext key are missing" do
      item = {"type" => "fobject",
              "id" => "test:1",
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
      expect(ROF.Ingest(item)).to eq(["rels-ext", "content"])
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

      it "handles @graph objects" do
        item = {"pid" => "test:1",
                "metadata" => {
                  "@context" => {
                    "dc" => "http://purl.org/dc/terms/",
                    "dc:creator" => {"@type" => "@id"},
                  },
                  "@graph" => [
                    {"@id" => "_:b0",
                     "dc:title" => "Hello"},
                    {"@id" => "info:fedora/test:1",
                     "dc:creator" => "_:b0"},
                  ]}}
        s = ROF.ingest_ld_metadata(item, nil)
        s = s.split("\n").sort.join("\n") # canonicalize the line ordering
        expect(s).to eq %(<info:fedora/test:1> <http://purl.org/dc/terms/creator> _:b0 .\n_:b0 <http://purl.org/dc/terms/title> "Hello" .)
      end
    end
  end

  describe "file_searching" do
    it "raises an error on missing files" do
      expect {ROF.find_file_and_open("file.txt",[],"r")}.to raise_error(Errno::ENOENT)
    end
  end
end
