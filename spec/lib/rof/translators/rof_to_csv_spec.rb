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

    it "handles double caret encoded data" do
      input = {
            "pid" => "temp:02",
            "type" => "fobject",
            "af-model" => "Etd",
            "rels-ext" => {
              "@context" => {
                "@vocab"=> "info:fedora/fedora-system:def/relations-external#",
                "fedora-model" => "info:fedora/fedora-system:def/model#",
                "pav" => "http://purl.org/pav/",
                "hydra" => "http://projecthydra.org/ns/relations#",
                "hydramata-rel" => "http://projecthydra.org/ns/relations#",
                "hasModel" => { "@id" => "fedora-model:hasModel", "@type" => "@id" },
                "hasEditor" => { "@id" => "hydra:hasEditor", "@type" => "@id" },
                "hasEditorGroup" => { "@id" => "hydra:hasEditorGroup", "@type" => "@id" },
                "hasViewer" => { "@id" => "hydra:hasViewer", "@type" => "@id" },
                "hasViewerGroup" => { "@id" => "hydra:hasViewerGroup", "@type" => "@id" },
                "isPartOf" => { "@type" => "@id" },
                "isMemberOfCollection" => { "@type" => "@id" },
                "isEditorOf" => { "@id" => "hydra:isEditorOf", "@type" => "@id" },
                "hasMember" => { "@type" => "@id" },
                "previousVersion" => "http://purl.org/pav/previousVersion"
              },
              "@id" => "temp:02",
              "hasEditor" => "und:qb98mc9021z",
              "hasEditorGroup" => "und:q524jm23g92"
            },
            "metadata" => {
              "@context" => {
                "bibo" => "http://purl.org/ontology/bibo/",
                "dc" => "http://purl.org/dc/terms/",
                "ebucore" => "http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#",
                "foaf" => "http://xmlns.com/foaf/0.1/",
                "hydramata-rel" => "http://projecthydra.org/ns/relations#",
                "hydra" => "http://projecthydra.org/ns/relations#",
                "mrel" => "http://id.loc.gov/vocabulary/relators/",
                "ms" => "http://www.ndltd.org/standards/metadata/etdms/1.1/",
                "nd" => "https://library.nd.edu/ns/terms/",
                "rdfs" => "http://www.w3.org/2000/01/rdf-schema#",
                "ths" => "http://id.loc.gov/vocabulary/relators/",
                "vracore" => "http://purl.org/vra/",
                "pav" => "http://purl.org/pav/",
                "dc:dateSubmitted" => { "@type" => "http://www.w3.org/2001/XMLSchema#date" },
                "dc:created" => { "@type" => "http://www.w3.org/2001/XMLSchema#date" },
                "dc:modified" => { "@type" => "http://www.w3.org/2001/XMLSchema#date" }
              },
              "@graph" => [
                {
                  "@id" => "_:b3",
                  "ms:name" => "Doctor of Philosophy",
                  "ms:discipline" => "Chemistry and Biochemistry",
                  "ms:level" => "Doctoral Dissertation"
                },
                {
                  "@id" => "_:b0",
                  "dc:contributor" => "Jane Doe",
                  "ms:role" => "Research Director"
                },
                {
                  "@id" => "info:fedora/temp:02",
                  "nd:alephIdentifier" => "000000001",
                  "dc:creator" => "Zoe Braid",
                  "dc:rights" => "All rights reserved",
                  "dc:modified" => "2020-02-22Z",
                  "ms:degree" => { "@id" => "_:b3" },
                  "dc:dateSubmitted" => "2020-01-09",
                  "dc:contributor" => [
                    {
                      "@id" => "_:b0"
                    },
                    {
                      "@id" => "_:b1"
                    }
                  ],
                  "dc:title" => "Adventures in Polymers",
                  "dc:date#approved" => "2020-02-17",
                  "dc:creator#administrative_unit" => "University of Notre Dame::College of Science::Chemistry and Biochemistry",
                  "dc:identifier#local" => "0000000001",
                  "dc:description#abstract" => "a long abstract"
                },
                {
                  "@id" => "_:b1",
                  "dc:contributor" => "Jane Doe",
                  "ms:role" => "Research Director"
                }
              ]
            },
            "rights" => {
              "read-groups" => [ "public" ],
              "read" => [ "wgan" ],
              "edit-groups" => [ "und:q524jm23g92" ],
              "edit" => [ "curate_batch_user" ]
            },
            "properties-meta" => { "mime-type" => "text/xml" },
            "properties" => "<fields><depositor>curate_batch_user</depositor><representative>temp:03</representative></fields>",
            "bendo-item" => "02"
          }
      result = RofToCsv.call([input], {sort_keys: true})
      expect(result).to eq(%q{access,af-model,bendo-item,dc:contributor,dc:creator,dc:creator#administrative_unit,dc:date#approved,dc:dateSubmitted,dc:description#abstract,dc:identifier#local,dc:modified,dc:rights,dc:title,ms:degree,nd:alephIdentifier,pid,representative,rof-type
"edit=und:qb98mc9021z,curate_batch_user;editgroup=und:q524jm23g92;read=wgan;readgroup=public",Etd,02,^^dc:contributor Jane Doe^^ms:role Research Director|^^dc:contributor Jane Doe^^ms:role Research Director,Zoe Braid,University of Notre Dame::College of Science::Chemistry and Biochemistry,2020-02-17,2020-01-09,a long abstract,0000000001,2020-02-22Z,All rights reserved,Adventures in Polymers,^^ms:discipline Chemistry and Biochemistry^^ms:level Doctoral Dissertation^^ms:name Doctor of Philosophy,000000001,temp:02,temp:03,fobject
} )
    end

    it "handles double caret encoded data not in a @graph" do
      input = {
            "pid" => "temp:02",
            "type" => "fobject",
            "af-model" => "Etd",
            "rels-ext" => {
              "@context" => {
                "@vocab"=> "info:fedora/fedora-system:def/relations-external#",
                "fedora-model" => "info:fedora/fedora-system:def/model#",
                "pav" => "http://purl.org/pav/",
                "hydra" => "http://projecthydra.org/ns/relations#",
                "hydramata-rel" => "http://projecthydra.org/ns/relations#",
                "hasModel" => { "@id" => "fedora-model:hasModel", "@type" => "@id" },
                "hasEditor" => { "@id" => "hydra:hasEditor", "@type" => "@id" },
                "hasEditorGroup" => { "@id" => "hydra:hasEditorGroup", "@type" => "@id" },
                "hasViewer" => { "@id" => "hydra:hasViewer", "@type" => "@id" },
                "hasViewerGroup" => { "@id" => "hydra:hasViewerGroup", "@type" => "@id" },
                "isPartOf" => { "@type" => "@id" },
                "isMemberOfCollection" => { "@type" => "@id" },
                "isEditorOf" => { "@id" => "hydra:isEditorOf", "@type" => "@id" },
                "hasMember" => { "@type" => "@id" },
                "previousVersion" => "http://purl.org/pav/previousVersion"
              },
              "@id" => "temp:02",
              "hasEditor" => "und:qb98mc9021z",
              "hasEditorGroup" => "und:q524jm23g92"
            },
            "metadata" => {
              "@context" => {
                "bibo" => "http://purl.org/ontology/bibo/",
                "dc" => "http://purl.org/dc/terms/",
                "ebucore" => "http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#",
                "foaf" => "http://xmlns.com/foaf/0.1/",
                "hydramata-rel" => "http://projecthydra.org/ns/relations#",
                "hydra" => "http://projecthydra.org/ns/relations#",
                "mrel" => "http://id.loc.gov/vocabulary/relators/",
                "ms" => "http://www.ndltd.org/standards/metadata/etdms/1.1/",
                "nd" => "https://library.nd.edu/ns/terms/",
                "rdfs" => "http://www.w3.org/2000/01/rdf-schema#",
                "ths" => "http://id.loc.gov/vocabulary/relators/",
                "vracore" => "http://purl.org/vra/",
                "pav" => "http://purl.org/pav/",
                "dc:dateSubmitted" => { "@type" => "http://www.w3.org/2001/XMLSchema#date" },
                "dc:created" => { "@type" => "http://www.w3.org/2001/XMLSchema#date" },
                "dc:modified" => { "@type" => "http://www.w3.org/2001/XMLSchema#date" }
              },
              "@id" => "info:fedora/temp:02",
              "dc:title" => "Adventures in Polymers",
              "dc:date#approved" => "2020-02-17",
              "dc:creator#administrative_unit" => "University of Notre Dame::College of Science::Chemistry and Biochemistry",
              "dc:identifier#local" => "0000000001",
              "dc:description#abstract" => "a long abstract",
              "nd:alephIdentifier" => "000000001",
                "dc:creator" => "Zoe Braid",
                "dc:rights" => "All rights reserved",
                "dc:modified" => "2020-02-22Z",
                "ms:degree" => { "ms:name" => "Doctor of Philosophy",
                                 "ms:discipline" => "Chemistry and Biochemistry",
                                 "ms:level" => "Doctoral Dissertation"
              },
              "dc:dateSubmitted" => "2020-01-09",
              "dc:contributor" => [
                {
                  "dc:contributor" => "Jane Doe",
                  "ms:role" => "Research Director"
                },
                {
                  "dc:contributor" => "Jane Doe",
                  "ms:role" => "Research Director"
                }
              ]
            },
            "rights" => {
              "read-groups" => [ "public" ],
              "read" => [ "wgan" ],
              "edit-groups" => [ "und:q524jm23g92" ],
              "edit" => [ "curate_batch_user" ]
            },
            "properties-meta" => { "mime-type" => "text/xml" },
            "properties" => "<fields><depositor>curate_batch_user</depositor><representative>temp:03</representative></fields>",
            "bendo-item" => "02"
          }
      result = RofToCsv.call([input], {sort_keys: true})
      expect(result).to eq(%q{access,af-model,bendo-item,dc:contributor,dc:creator,dc:creator#administrative_unit,dc:date#approved,dc:dateSubmitted,dc:description#abstract,dc:identifier#local,dc:modified,dc:rights,dc:title,ms:degree,nd:alephIdentifier,pid,representative,rof-type
"edit=und:qb98mc9021z,curate_batch_user;editgroup=und:q524jm23g92;read=wgan;readgroup=public",Etd,02,^^dc:contributor Jane Doe^^ms:role Research Director|^^dc:contributor Jane Doe^^ms:role Research Director,Zoe Braid,University of Notre Dame::College of Science::Chemistry and Biochemistry,2020-02-17,2020-01-09,a long abstract,0000000001,2020-02-22Z,All rights reserved,Adventures in Polymers,^^ms:discipline Chemistry and Biochemistry^^ms:level Doctoral Dissertation^^ms:name Doctor of Philosophy,000000001,temp:02,temp:03,fobject
} )
    end
  end
end
