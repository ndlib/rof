require 'spec_helper'

module ROF
  describe "Access" do
    it "decodes public restricted private" do
      s = Access.decode("public", "user1")
      expect(s).to eq({"read-groups" => ["public"], "edit" => ["user1"]})

      s = Access.decode("restricted", "user1")
      expect(s).to eq({"read-groups" => ["registered"], "edit" => ["user1"]})

      s = Access.decode("private", "user1")
      expect(s).to eq({"edit" => ["user1"]})
    end

    it "handles embargos" do
      s = Access.decode("embargo=2014-12-25", "user1")
      expect(s).to eq({"embargo-date" => "2014-12-25"})
    end

    it "handles multiple clauses" do
      s = Access.decode("public;editgroup=group1,group2;edit=user2", "user1")
      expect(s).to eq({"read-groups" => ["public"], "edit" => ["user1","user2"], "edit-groups" => ["group1","group2"]})
    end

    it "removes duplicates" do
      s = Access.decode("edit=user1,user2;edit=user1")
      expect(s).to eq({"edit" => ["user1", "user2"]})
    end

    it "encodes" do
      s = Access.encode({"read-groups" => ["public"], "edit" => ["user1","user2"], "edit-groups" => ["group1","group2"]})
      expect(s).to eq("readgroup=public;edit=user1,user2;editgroup=group1,group2")
    end
  end
end
