require 'spec_helper'

module ROF
  describe "Compare ROF" do
    it "compares rights metadata different read-groups" do
      fedora = { "rights"=> { "read-groups"=> ["public"], "edit"=> ["rtillman"]}}
      bendo = { "rights"=> {"read-groups"=> ["private"], "edit"=> ["rtillman"]}}
      test_return = CompareRof.compare_rights(fedora, bendo, {})
      expect(test_return).to eq(1)
    end

    it "compares rights metadata same read-groups" do
      fedora = { "rights"=> { "read-groups"=> ["public"], "edit"=> ["rtillman"]}}
      bendo = { "rights"=> {"read-groups"=> ["public"], "edit"=> ["rtillman"]}}
      test_return = CompareRof.compare_rights(fedora, bendo, {})
      expect(test_return).to eq(0)
    end

    it "compares rights metadata with different groups" do
      fedora = { "rights"=> { "read-groups"=> ["public"], "edit"=> ["rtillman"]}}
      bendo = { "rights"=> {"edit"=> ["rtillman"]}}
      test_return = CompareRof.compare_rights(fedora, bendo, {})
      expect(test_return).to eq(1)
    end

    it "compares metadata (same) " do
      fedora = { "metadata"=> { "@context"=> {
            "dc"=> "http://purl.org/dc/terms/",
            "foaf"=> "http://xmlns.com/foaf/0.1/",
            "rdfs"=> "http://www.w3.org/2000/01/rdf-schema#",
            "dc:dateSubmitted"=> {
              "@type"=> "http://www.w3.org/2001/XMLSchema#date"
            },
            "dc:modified"=> {
	            "@type"=> "http://www.w3.org/2001/XMLSchema#date"
	          }
          },
          "dc:dateSubmitted"=> "2016-07-22Z",
          "dc:modified"=> "2016-07-22Z",
          "dc:title"=> "carmella.jpeg"
        }}
      bendo = { "metadata"=> {
          "dc:dateSubmitted"=> "2016-07-22Z",
          "dc:modified"=> "2016-07-22Z",
          "dc:title"=> "carmella.jpeg"
        }}
      test_return = CompareRof.compare_metadata(fedora, bendo, {})
      expect(test_return).to eq(0)
    end

    it "compares metadata (different) " do
      fedora = { "metadata"=> { "@context"=> {
            "dc"=> "http://purl.org/dc/terms/",
            "foaf"=> "http://xmlns.com/foaf/0.1/",
            "rdfs"=> "http://www.w3.org/2000/01/rdf-schema#",
            "dc:dateSubmitted"=> {
              "@type"=> "http://www.w3.org/2001/XMLSchema#date"
            },
            "dc:modified"=> {
	            "@type"=> "http://www.w3.org/2001/XMLSchema#date"
	          }
          },
          "dc:dateSubmitted"=> "2016-07-22Z",
          "dc:modified"=> "2016-07-22Z",
          "dc:title"=> "carmella.jpeg"
        }}
      bendo = { "metadata"=> {
          "dc:dateSubmitted"=> "2016-07-22Z",
          "dc:modified"=> "2016-07-23Z",
          "dc:title"=> "carmella.jpeg"
        }}
      test_return = CompareRof.compare_metadata(fedora, bendo, {})
      expect(test_return).to eq(1)
    end

    it "compares rels-ext (same) " do
      fedora = { "rels-ext"=> {
		    "@context"=> {
		      "@vocab"=> "info:fedora/fedora-system:def/relations-external#",
	              "fedora-model"=> "info:fedora/fedora-system:def/model#",
	              "hydra"=> "http://projecthydra.org/ns/relations#",
	              "hasModel"=> {
		            "@id"=> "fedora-model:hasModel",
		            "@type"=> "@id"
	              },
	              "hasEditor"=> {
	                "@id"=> "hydra:hasEditor",
	                "@type"=> "@id"
	              },
	              "hasEditorGroup"=> {
	                "@id"=> "hydra:hasEditorGroup",
	                "@type"=> "@id"
	              },
	              "isPartOf"=> {
	                "@type"=> "@id"
	              },
	              "isEditorOf"=> {
	                "@id"=> "hydra:isEditorOf",
	                "@type"=> "@id"
	              },
	              "hasMember"=> {
	                "@type"=> "@id"
	              }
	            },
	            "isPartOf"=> [
		      "und:dev00149x01"
	            ]
	}}
        bendo = { "rels-ext"=> {
	            "isPartOf"=> [
		      "und:dev00149x01"
	            ]
	}}
      test_return = CompareRof.compare_rels_ext(fedora, bendo, {})
      expect(test_return).to eq(0)
    end

    it "compares rels-ext (different) " do
      fedora = { "rels-ext"=> {
		    "@context"=> {
		      "@vocab"=> "info:fedora/fedora-system:def/relations-external#",
	              "fedora-model"=> "info:fedora/fedora-system:def/model#",
	              "hydra"=> "http://projecthydra.org/ns/relations#",
	              "hasModel"=> {
		            "@id"=> "fedora-model:hasModel",
		            "@type"=> "@id"
	              },
	              "hasEditor"=> {
	                "@id"=> "hydra:hasEditor",
	                "@type"=> "@id"
	              },
	              "hasEditorGroup"=> {
	                "@id"=> "hydra:hasEditorGroup",
	                "@type"=> "@id"
	              },
	              "isPartOf"=> {
	                "@type"=> "@id"
	              },
	              "isEditorOf"=> {
	                "@id"=> "hydra:isEditorOf",
	                "@type"=> "@id"
	              },
	              "hasMember"=> {
	                "@type"=> "@id"
	              }
	            },
	            "isPartOf"=> [
		      "und:dev00149x01"
	            ]
	}}
        bendo = { "rels-ext"=> {
	            "isPartOf"=> [
		      "und:dev00148x01"
	            ]
	}}
      test_return = CompareRof.compare_rels_ext(fedora, bendo, {})
      expect(test_return).to eq(1)
    end

    it "compares everything else (same) " do
      fedora = {
	        "pid"=> "und:dev00149w5f",
                "type"=> "fobject",
                "af-model"=> "Collection",
                "properties-meta"=> {
	          "mime-type"=> "text/xml"
	       },
               "properties"=> "<fields><depositor>batch_ingest</depositor>\n\t\t\t\t<owner>rtillman</owner></fields>\n",
	       "content-meta"=> {
	         "mime-type"=> "image/jpeg"
	       },
	       "thumbnail-meta"=> {
	         "mime-type"=> "image/jpeg"
	       },
	       "bendo-item"=> "dev00149w5f"
       }
      bendo = {
               "properties-meta"=> {
	          "mime-type"=> "text/xml"
	       },
               "properties"=> "<fields><depositor>batch_ingest</depositor>\n\t\t\t\t<owner>rtillman</owner></fields>\n",
	       "content-meta"=> {
	         "mime-type"=> "image/jpeg"
	       },
               "af-model"=> "Collection",
	       "pid"=> "und:dev00149w5f",
	       "thumbnail-meta"=> {
	         "mime-type"=> "image/jpeg"
	       },
               "type"=> "fobject",
	       "bendo-item"=> "dev00149w5f"
	}
      test_return = CompareRof.compare_everything_else(fedora, bendo, {})
      expect(test_return).to eq(0)
    end

    it "compares everything else (differenet) " do
      fedora = {
	        "pid"=> "und:dev00149w5f",
                "type"=> "fobject",
                "af-model"=> "Collection",
                "properties-meta"=> {
	          "mime-type"=> "text/xml"
	       },
               "properties"=> "<fields><depositor>batch_ingest</depositor>\n\t\t\t\t<owner>msuhovec</owner></fields>\n",
	       "content-meta"=> {
	         "mime-type"=> "image/jpeg"
	       },
	       "thumbnail-meta"=> {
	         "mime-type"=> "image/jpeg"
	       },
	       "bendo-item"=> "dev00149w5f"
       }
      bendo = {
               "properties-meta"=> {
	          "mime-type"=> "text/xml"
	       },
               "properties"=> "<fields><depositor>batch_ingest</depositor>\n\t\t\t\t<owner>rtillman</owner></fields>\n",
	       "content-meta"=> {
	         "mime-type"=> "image/jpeg"
	       },
               "af-model"=> "Collection",
	       "pid"=> "und:dev00149w5f",
	       "thumbnail-meta"=> {
	         "mime-type"=> "image/jpeg"
	       },
               "type"=> "fobject",
	       "bendo-item"=> "dev00149w5f"
	}
      test_return = CompareRof.compare_everything_else(fedora, bendo, {})
      expect(test_return).to eq(1)
    end
  end
end
