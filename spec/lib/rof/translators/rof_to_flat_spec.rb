require 'spec_helper'

module ROF
  module Translators
    RSpec.describe RofToFlat do
      table = [{
        filename: 'spec/fixtures/jsonld_to_rof/0g354f18610.rof',
        value: "(record
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
        )"
      }, {
        filename: 'spec/fixtures/jsonld_to_rof/p8418k7430d.rof',
        value: "(record
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
        )"
      }]
      table.each do |test_case|
        it 'decodes ' + test_case[:filename] do
          roffile = JSON.load(File.read(File.join(GEM_ROOT, test_case[:filename])))
          output = described_class.call(roffile, {})
          expect(output.first).to eq(ROF::Flat.from_sexp(test_case[:value]))
        end
      end
    end
  end
end
