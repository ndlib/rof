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
    it "rejects two ways of giving a datastream" do
      item = {"type" => "fobject",
              "pid" => "test:1",
              "content" => "hello",
              "content-file" => "filename.txt"
      }
      expect {ROF.Ingest(item)}.to raise_error(ROF::SourceError)
    end
  end
end
