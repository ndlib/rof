require 'spec_helper'

module ROF
  module Translators
    RSpec.describe FlatToRof do
      table = [{
        filename: 'spec/fixtures/jsonld_to_rof/0g354f18610.rof',
        record: "(record
          (af-model Etd)
          (dc:contributor ^^dc:contributor Andrew S. Park^^ms:role Committee Member)
          (dc:contributor ^^dc:contributor David Clairmont^^ms:role Committee Member)
          (dc:contributor ^^dc:contributor Jean Porter^^ms:role Committee Member)
          (dc:contributor ^^dc:contributor Maura Ryan^^ms:role Research Director)
          (dc:creator Joungeun Lee)
          (dc:date 2015-06-29)
          (dc:dateSubmitted 2016-02-18Z)
          (dc:description#abstract <p>The goal of this dissertation is to bring together in conversation Aquinas's thoughts on anger and the <i>han</i> (恨)-full anger as a culture-bound syndrome in South Korean people and society, and to make a constructive proposal for working with the anger of the <i>han</i>-filled. Aquinas' ontological cognitivist theory of passion and anger in particular provides a useful hermeneutical tool to analyze and articulate the inner structure of <i>han</i>-full anger and its moral character. The study of <i>han</i>-full anger offers Aquinas’s normative language of anger a chance to encounter the etymological and phenomenological reality of embodied anger and further the life of its bearer living in a marginalized life. Finally, Aquinas’s virtue ethics, taken together with <i>han</i> studies, suggests a modified way to work with the <i>han</i>-full anger. </p>)
          (dc:modified 2016-02-19Z)
          (dc:rights All rights reserved)
          (dc:title Anger in Thomas Aquinas and <i>Han</i>-full Anger)
          (depositor curate_batch_user)
          (edit-group und:q524jm23g92)
          (edit-person und:qb98mc9021z)
          (edit-person curate_batch_user)
          (embargo-date 2016-02-28)
          (ms:degree ^^ms:discipline Philosophy^^ms:level Doctoral Dissertation^^ms:name Doctor of Philosophy)
          (pid und:0g354f18610)
          (read-group public)
          (read-person jlee20)
          (representative und:rv042r3997b)
          (rof-type fobject)
        )",
        rof: [{
          'pid' => 'und:0g354f18610',
          'type' => 'fobject',
          'af-model' => 'Etd',
          'properties' => "<fields><depositor>curate_batch_user</depositor>\n<owner></owner>\n<representative>und:rv042r3997b</representative>\n</fields>\n",
          'properties-meta' => { 'mime-type' => 'text/xml' },
          'rels-ext' => { 'hasEditor' => ['und:qb98mc9021z'], 'hasEditorGroup' => ['und:q524jm23g92'] },
          'rights' => { 'read' => ['jlee20'], 'read-groups' => ['public'], 'edit' => ['und:qb98mc9021z', 'curate_batch_user'], 'edit-groups' => ['und:q524jm23g92'], 'embargo-date' => '2016-02-28' },
          'metadata' => {
            'dc:contributor' => [{ 'dc:contributor' => 'Andrew S. Park', 'ms:role' => 'Committee Member' },
                                 { 'dc:contributor' => 'David Clairmont', 'ms:role' => 'Committee Member' },
                                 { 'dc:contributor' => 'Jean Porter', 'ms:role' => 'Committee Member' },
                                 { 'dc:contributor' => 'Maura Ryan', 'ms:role' => 'Research Director' }],
            'dc:creator' => 'Joungeun Lee',
            'dc:date' => '2015-06-29',
            'dc:dateSubmitted' => '2016-02-18Z',
            'dc:description#abstract' => "<p>The goal of this dissertation is to bring together in conversation Aquinas's thoughts on anger and the <i>han</i> (恨)-full anger as a culture-bound syndrome in South Korean people and society, and to make a constructive proposal for working with the anger of the <i>han</i>-filled. Aquinas' ontological cognitivist theory of passion and anger in particular provides a useful hermeneutical tool to analyze and articulate the inner structure of <i>han</i>-full anger and its moral character. The study of <i>han</i>-full anger offers Aquinas’s normative language of anger a chance to encounter the etymological and phenomenological reality of embodied anger and further the life of its bearer living in a marginalized life. Finally, Aquinas’s virtue ethics, taken together with <i>han</i> studies, suggests a modified way to work with the <i>han</i>-full anger. </p>",
            'dc:modified' => '2016-02-19Z',
            'dc:rights' => 'All rights reserved',
            'dc:title' => 'Anger in Thomas Aquinas and <i>Han</i>-full Anger',
            'ms:degree' => { 'ms:discipline' => 'Philosophy', 'ms:level' => 'Doctoral Dissertation', 'ms:name' => 'Doctor of Philosophy' },
            '@context' => { 'bibo' => 'http://purl.org/ontology/bibo/', 'dc' => 'http://purl.org/dc/terms/', 'ebucore' => 'http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#', 'foaf' => 'http://xmlns.com/foaf/0.1/', 'hydramata-rel' => 'http://projecthydra.org/ns/relations#', 'hydra' => 'http://projecthydra.org/ns/relations#', 'mrel' => 'http://id.loc.gov/vocabulary/relators/', 'ms' => 'http://www.ndltd.org/standards/metadata/etdms/1.1/', 'nd' => 'https://library.nd.edu/ns/terms/', 'rdfs' => 'http://www.w3.org/2000/01/rdf-schema#', 'ths' => 'http://id.loc.gov/vocabulary/relators/', 'vracore' => 'http://purl.org/vra/', 'pav' => 'http://purl.org/pav/', 'dc:dateSubmitted' => { '@type' => 'http://www.w3.org/2001/XMLSchema#date' }, 'dc:created' => { '@type' => 'http://www.w3.org/2001/XMLSchema#date' }, 'dc:modified' => { '@type' => 'http://www.w3.org/2001/XMLSchema#date' } }
          }
        }]
      }, {
        filename: 'spec/fixtures/jsonld_to_rof/p8418k7430d.rof',
        record: "(record
          (af-model Patent)
          (dc:creator Bruno Kristiaan Bernard De Man)
          (dc:creator Charles Addison Bouman Jr.)
          (dc:creator Jean-Baptiste Daniel Marie Thibault)
          (dc:creator Jiang Hsieh)
          (dc:creator Kai Zeng)
          (dc:creator Ken David Sauer)
          (dc:creator Zhou Yu)
          (dc:creator#administrative_unit University of Notre Dame::College of Engineering::Electrical Engineering)
          (dc:creator#local Ken David Sauer)
          (dc:date#application 2009-10-28)
          (dc:date#prior_publication 2011-04-28)
          (dc:dateSubmitted 2016-06-07Z)
          (dc:description An improved iterative reconstruction method to reconstruct a first image includes generating an imaging beam, receiving said imaging beam on a detector array, generating projection data based on said imaging beams received by said detector array, providing said projection data to an image reconstructor, enlarging one of a plurality of voxels and a plurality of detectors of the provided projection data, reconstructing portions of the first image with the plurality of enlarged voxels or detectors, and iteratively reconstructing the portions of the first image to create a reconstructed image.)
          (dc:extent#claims 32)
          (dc:identifier#other_application 12/607,309)
          (dc:identifier#patent US 8655033 B2)
          (dc:identifier#prior_publication US 20110097007 A1)
          (dc:issued 2014-02-18)
          (dc:language eng)
          (dc:modified 2016-06-07Z)
          (dc:publisher United States Patent and Trademark Office)
          (dc:rights http://creativecommons.org/publicdomain/zero/1.0/)
          (dc:rightsHolder General Electric Company (Schenectady, NY))
          (dc:rightsHolder Purdue Research Foundation (West Lafayette, IN))
          (dc:rightsHolder University of Notre Dame Du Lac)
          (dc:source http://patft.uspto.gov/netacgi/nph-Parser?Sect2=PTO1&Sect2=HITOFF&p=1&u=/netahtml/PTO/search-bool.html&r=1&f=G&l=50&d=PALL&RefSrch=yes&Query=PN/8655033)
          (dc:subject#cpc G06T 11/006 (20130101); G06T 2211/424 (20130101))
          (dc:subject#ipc G06K 9/00)
          (dc:subject#uspc 382/128; 382/131;)
          (dc:title Iterative Reconstruction)
          (depositor batch_ingest)
          (edit-person rtillman)
          (owner rtillman)
          (pid und:p8418k7430d)
          (read-group public)
          (representative und:pc289g57c13)
          (rof-type fobject)
        )",
        rof: [{
          'pid' => 'und:p8418k7430d',
          'type' => 'fobject',
          'af-model' => 'Patent',
          'properties' => "<fields><depositor>batch_ingest</depositor>\n<owner>rtillman</owner>\n<representative>und:pc289g57c13</representative>\n</fields>\n",
          'properties-meta' => { 'mime-type' => 'text/xml' },
          'rels-ext' => {},
          'rights' => { 'read-groups' => ['public'], 'edit' => ['rtillman'] },
          'metadata' => {
            'dc:creator' => ['Bruno Kristiaan Bernard De Man', 'Charles Addison Bouman Jr.', 'Jean-Baptiste Daniel Marie Thibault', 'Jiang Hsieh', 'Kai Zeng', 'Ken David Sauer', 'Zhou Yu'],
            'dc:creator#administrative_unit' => 'University of Notre Dame::College of Engineering::Electrical Engineering',
            'dc:creator#local' => 'Ken David Sauer',
            'dc:date#application' => '2009-10-28',
            'dc:date#prior_publication' => '2011-04-28',
            'dc:dateSubmitted' => '2016-06-07Z',
            'dc:description' => 'An improved iterative reconstruction method to reconstruct a first image includes generating an imaging beam, receiving said imaging beam on a detector array, generating projection data based on said imaging beams received by said detector array, providing said projection data to an image reconstructor, enlarging one of a plurality of voxels and a plurality of detectors of the provided projection data, reconstructing portions of the first image with the plurality of enlarged voxels or detectors, and iteratively reconstructing the portions of the first image to create a reconstructed image.',
            'dc:extent#claims' => '32',
            'dc:identifier#other_application' => '12/607,309',
            'dc:identifier#patent' => 'US 8655033 B2',
            'dc:identifier#prior_publication' => 'US 20110097007 A1',
            'dc:issued' => '2014-02-18',
            'dc:language' => 'eng',
            'dc:modified' => '2016-06-07Z',
            'dc:publisher' => 'United States Patent and Trademark Office',
            'dc:rights' => 'http://creativecommons.org/publicdomain/zero/1.0/',
            'dc:rightsHolder' => ['General Electric Company (Schenectady, NY)', 'Purdue Research Foundation (West Lafayette, IN)', 'University of Notre Dame Du Lac'],
            'dc:source' => 'http://patft.uspto.gov/netacgi/nph-Parser?Sect2=PTO1&Sect2=HITOFF&p=1&u=/netahtml/PTO/search-bool.html&r=1&f=G&l=50&d=PALL&RefSrch=yes&Query=PN/8655033',
            'dc:subject#cpc' => 'G06T 11/006 (20130101); G06T 2211/424 (20130101)',
            'dc:subject#ipc' => 'G06K 9/00',
            'dc:subject#uspc' => '382/128; 382/131;',
            'dc:title' => 'Iterative Reconstruction',
            '@context' => { 'bibo' => 'http://purl.org/ontology/bibo/', 'dc' => 'http://purl.org/dc/terms/', 'ebucore' => 'http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#', 'foaf' => 'http://xmlns.com/foaf/0.1/', 'hydramata-rel' => 'http://projecthydra.org/ns/relations#', 'hydra' => 'http://projecthydra.org/ns/relations#', 'mrel' => 'http://id.loc.gov/vocabulary/relators/', 'ms' => 'http://www.ndltd.org/standards/metadata/etdms/1.1/', 'nd' => 'https://library.nd.edu/ns/terms/', 'rdfs' => 'http://www.w3.org/2000/01/rdf-schema#', 'ths' => 'http://id.loc.gov/vocabulary/relators/', 'vracore' => 'http://purl.org/vra/', 'pav' => 'http://purl.org/pav/', 'dc:dateSubmitted' => { '@type' => 'http://www.w3.org/2001/XMLSchema#date' }, 'dc:created' => { '@type' => 'http://www.w3.org/2001/XMLSchema#date' }, 'dc:modified' => { '@type' => 'http://www.w3.org/2001/XMLSchema#date' } }
          }
        }]
      }]
      table.each do |test_case|
        it 'encodes ' + test_case[:filename] do
          record = ROF::Flat.from_sexp(test_case[:record])
          output = described_class.call([record])
          expect(output).to eq(test_case[:rof])
        end
      end
    end
  end
end
