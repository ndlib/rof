module ROF
  OsfPrefixList = {
    'dcterms' => 'http://purl.org/dc/terms/',
    'osf-model' => 'http://www.dataconservancy.org/osf-business-object-model#'
  }.freeze

  OsfToNDMap = {
    'dc:created' => 'http://purl.org/dc/terms/created',
    'dc:description' => 'http://purl.org/dc/terms/description',
    'dc:title' => 'http://purl.org/dc/terms/title',
    'dc:subject' => 'http://www.dataconservancy.org/osf-business-object-model#hasTag',
    'isPublic' => 'http://www.dataconservancy.org/osf-business-object-model#isPublic',
    'hasContributor' => 'http://www.dataconservancy.org/osf-business-object-model#hasContributor',
    'isBibliographic' => 'http://www.dataconservancy.org/osf-business-object-model#isBibliographic',
    'hasFullName' => 'http://www.dataconservancy.org/osf-business-object-model#hasFullName',
    'hasUser' => 'http://www.dataconservancy.org/osf-business-object-model#hasUser',
    'registeredFrom' => 'http://www.dataconservancy.org/osf-business-object-model#registeredFrom'
  }.freeze
end
