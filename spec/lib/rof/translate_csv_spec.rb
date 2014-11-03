require 'spec_helper'

module ROF
  describe "translate CSV" do
    it "requires the columns type and owner" do
      s = "dc:title,access,owner"
      expect{TranslateCSV.run(s)}.to raise_error

      s = "dc:title,access,type"
      expect{TranslateCSV.run(s)}.to raise_error

      s = "dc:title,type,owner,access"
      expect(TranslateCSV.run(s)).to eq([])
    end

    it "requires rows to have an owner and type" do
      s = %q{type,owner
      Work,
      }
      expect{TranslateCSV.run(s)}.to raise_error
    end

    it "does not split the access field on pipe" do
      s = %q{type,owner,access
      Work,user1,"private,edit:user2|user3"
      }
      rof = TranslateCSV.run(s)
      expect(rof).to eq([{"type" => "Work", "owner" => "user1", "access" => "private,edit:user2|user3"}])
    end

  end
end
