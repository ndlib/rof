require 'spec_helper'

module ROF
  describe CompareRof do
    it "returns zero for eqivalent objects" do
      test1 = { 'owner' => 'rtillman', 'rights' => { 'read-groups' => [ 'public' ], 'edit' => [ 'edit']}}  
      test2 = { 'owner' => 'rtillman', 'rights' => { 'read-groups' => [ 'public' ], 'edit' => [ 'edit']}} 

      s = CompareRof.fedora_vs_bendo( test1, test2 , 'STDOUT') 
      expect(s).to eq(2)
    end
  end
end
