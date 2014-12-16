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
end
