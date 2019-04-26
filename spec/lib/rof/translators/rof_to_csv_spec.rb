require 'spec_helper'

module ROF::Translators
  describe "translate ROF" do
    it "pulls rights from both rels-ext and rights fields" do
      input = {
        "rels-ext" => {
          "hasViewerGroup" => ["und:0", "und:1"]
        },
        "rights" => {
          "read-groups" => ["some_people"],
          "edit" => ["jdoe"]
        }
      }
      rights = RofToCsv.decode_rights(input)
      expect(rights).to eq("readgroup=und:0,und:1,some_people;edit=jdoe")
    end
    
    it "decodes rof into correct fields" do
    input = {
        "pid" => "temp:01",
        "type" => "fobject",
        "bendo-item" => "0123456789",
        "af-model" => "GenericFile",
        "properties" => "<properties><owner>jdoe</owner></properties>",
        "rels-ext" => { "hasModel" => "GenericFile", "@context" => {}, "hasEditorGroup" => ["temp:02"], "isPartOf" => ["temp:03"] },
        "rights" => {"read-groups" => "public", "edit" => "jdoe" },
        "content-meta" => {"URL" => "bendo:/item/01/some_file/here.pdf", "mime-type" => "text/json", "label" => "here.pdf"},
        "metadata" => {"@context" => {}, "dc:title" => "here" }
      }
      result = RofToCsv.call([input])
      expect(result).to eq(%q{pid,rof-type,af-model,bendo-item,access,isPartOf,owner,file-URL,file-mime-type,filename,file-with-path,dc:title
temp:01,fobject,GenericFile,0123456789,editgroup=temp:02;readgroup=public;edit=jdoe,temp:03,jdoe,bendo:/item/01/some_file/here.pdf,text/json,here.pdf,some_file/here.pdf,here
} )
    end
  end
end