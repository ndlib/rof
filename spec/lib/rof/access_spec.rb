require 'spec_helper'

module ROF
  RSpec.describe Access do
    context '.decode' do
      it 'raises an error on an unknown clause' do
        expect { Access.decode("chicken") }.to raise_error described_class::DecodeError
      end
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
    end

    context '.encode' do
      it "converts a Hash to a String" do
        s = Access.encode({"read-groups" => ["public"], "edit" => ["user1","user2"], "edit-groups" => ["group1","group2"]})
        expect(s).to eq("readgroup=public;edit=user1,user2;editgroup=group1,group2")
      end
    end
  end
end
