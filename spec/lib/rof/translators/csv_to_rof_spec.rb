require 'spec_helper'

module ROF::Translators
  describe "translate CSV" do
    it "requires rows to have an owner and type" do
      s = %q{type,owner
      Work,
      }
      expect{CsvToRof.call(s)}.to raise_error(ROF::Translators::CsvToRof::MissingOwnerOrType)
    end

    it "deocdes the access field into rights" do
      s = %q{type,owner,access
      Work,user1,"private;edit=user2,user3"
      }
      rof = CsvToRof.call(s)
      expect(rof).to eq([{"type" => "Work", "owner" => "user1", "rights" => {"edit" => ["user1", "user2", "user3"]}}])
    end

    it "puts metadata into substructure" do
      s = %q{type,owner,dc:title,foaf:name
      Work,user1,"Q, A Letter",Jane Smith|Zander
      }
      rof = CsvToRof.call(s)
      expect(rof).to eq([{
        "type" => "Work",
        "owner" => "user1",
        "rights" => {"edit" => ["user1"]},
        "metadata" => {
          "@context" => ROF::RdfContext,
          "dc:title" => "Q, A Letter",
          "foaf:name" => ["Jane Smith", "Zander"]}
      }])
    end

    it "renames curate_id to pid" do
      s = %q{type,owner,curate_id
      Work,user1,abcdefg
      }
      rof = CsvToRof.call(s)
      expect(rof).to eq([{
        "type" => "Work",
        "owner" => "user1",
        "pid" => "abcdefg",
        "rights" => {"edit" => ["user1"]}
      }])
    end

    it "strips space around pipes" do
      s = %q{type,owner,dc:title,foaf:name
      Work,user1,"Q, A Letter",Jane Smith | Zander
      }
      rof = CsvToRof.call(s)
      expect(rof).to eq([{
        "type" => "Work",
        "owner" => "user1",
        "rights" => {"edit" => ["user1"]},
        "metadata" => {
          "@context" => ROF::RdfContext,
          "dc:title" => "Q, A Letter",
          "foaf:name" => ["Jane Smith", "Zander"]}
      }])
    end

    it "handles follow-on generic files" do
      s = %q{type,owner,dc:title,files
      Work,user1,"Q, A Letter",thumb
      +,user1,,extra file.txt
      }
      rof = CsvToRof.call(s)
      expect(rof).to eq([{
        "type" => "Work",
        "owner" => "user1",
        "rights" => {"edit" => ["user1"]},
        "metadata" => {
          "@context" => ROF::RdfContext,
          "dc:title" => "Q, A Letter"},
        "files" => [
          "thumb",
          {
            "type"  => "+",
            "owner" => "user1",
            "files" => ["extra file.txt"],
            "rights" => {"edit" => ["user1"]}
          }]
      }])
    end

    it "raises an error if a follow-on file has no preceeding work" do
      s = %q{type,owner,dc:title,files
      +,user1,,extra file.txt
      }
      expect {CsvToRof.call(s)}.to raise_error(ROF::Translators::CsvToRof::NoPriorWork)
    end


  end
end
