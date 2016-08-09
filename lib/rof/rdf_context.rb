module ROF
  RdfContext = {
    "dc" => "http://purl.org/dc/terms/",
    "foaf" => "http://xmlns.com/foaf/0.1/",
    "rdfs" => "http://www.w3.org/2000/01/rdf-schema#",

    "dc:dateSubmitted" => {
      "@type" => "http://www.w3.org/2001/XMLSchema#date"
    },
    "dc:modified" => {
      "@type" => "http://www.w3.org/2001/XMLSchema#date"
    }
  }.freeze

  RelsExtRefContext = {
      "@vocab" => "info:fedora/fedora-system:def/relations-external#",
      "fedora-model" => "info:fedora/fedora-system:def/model#",
      "hydra" => "http://projecthydra.org/ns/relations#",
      "hasModel" => {"@id" => "fedora-model:hasModel", "@type" => "@id"},
      "hasEditor" => {"@id" => "hydra:hasEditor", "@type" => "@id"},
      "hasEditorGroup" => {"@id" => "hydra:hasEditorGroup", "@type" => "@id"},
      "isPartOf" => {"@type" => "@id"},
      "isMemberOfCollection" => {"@type" => "@id"},
      "isEditorOf" => {"@id" => "hydra:isEditorOf", "@type" => "@id"},
      "hasMember" => {"@type" => "@id"},
  }.freeze
end
