module ROF
  RdfContext = {
    'bibo' => 'http://purl.org/ontology/bibo/',
    'dc' => 'http://purl.org/dc/terms/',
    'ebucore' => 'http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#',
    'foaf' => 'http://xmlns.com/foaf/0.1/',
    'hydramata-rel' => 'http://projecthydra.org/ns/relations#',
    'mrel' => 'http://id.loc.gov/vocabulary/relators/',
    'ms' => 'http://www.ndltd.org/standards/metadata/etdms/1.1/',
    'nd' => 'https://library.nd.edu/ns/terms/',
    'rdfs' => 'http://www.w3.org/2000/01/rdf-schema#',
    'ths' => 'http://id.loc.gov/vocabulary/relators/',
    'vracore' => 'http://purl.org/vra/',

    'dc:dateSubmitted' => {
      '@type' => 'http://www.w3.org/2001/XMLSchema#date'
    },
    'dc:created' => {
      '@type' => 'http://www.w3.org/2001/XMLSchema#date'
    },
    'dc:modified' => {
      '@type' => 'http://www.w3.org/2001/XMLSchema#date'
    }
  }.freeze

  RelsExtRefContext = {
    '@vocab' => 'info:fedora/fedora-system:def/relations-external#',
    'fedora-model' => 'info:fedora/fedora-system:def/model#',
    'hydra' => 'http://projecthydra.org/ns/relations#',
    'hasModel' => { '@id' => 'fedora-model:hasModel', '@type' => '@id' },
    'hasEditor' => { '@id' => 'hydra:hasEditor', '@type' => '@id' },
    'hasEditorGroup' => { '@id' => 'hydra:hasEditorGroup', '@type' => '@id' },
    'isPartOf' => { '@type' => '@id' },
    'isMemberOfCollection' => { '@type' => '@id' },
    'isEditorOf' => { '@id' => 'hydra:isEditorOf', '@type' => '@id' },
    'hasMember' => { '@type' => '@id' },
    'previousVersion' => 'http://purl.org/pav/previousVersion'
  }.freeze
end
