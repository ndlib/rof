# Bulk Ingest

Q. What does this hope to be?
A. An intermediate representation we can use to process ingests to fedora. The
idea is that we can accept any crazy format for bulk data and translate it into
this format. Then another piece can load this format into Fedora. Perhaps it
can also be used as an export format.

Q. What is its name?
A. I don't know. I was calling it ROF for Raw Object Format. I'm open to
suggestions. Jeremy?

Q. What is it?
A. ROF hopes to support many levels of abstraction. To begin with, it only
specifies a low level format based around the Fedora object model, whereby one
lists all the data streams which constitute each object. It handles some mild
translating for hydra rights metadata, but otherwise it is as dumb as a box of
rocks. It is designed to be easy for machines to process (NOT humans) and is
uses JSON format as its base. I see it supporting more abstract data elements,
say "article + dataset" in time.

Q. At what level does it hope to model objects? That is, why not just use FOXML?
A. Ideally, this will model our content using our data models. Unfortunately,
our data models are not well defined, and are still changing. Because of this,
if we did model the content at the data model level we would need to change the
loader whenever we add a new model. To begin with, ROF will describe what items
should look like in Fedora, in terms of Fedora objects. FOXML is too detailed
for our purpurses since it includes previous versions of content and an audit
log. Additionally, Hydra only uses a subset of Fedora. ROF will focus on the
parts which are important to us. And then we can extend it over time to handle
more abstract objects.

Q. So what are the problems with this format?
A. Ideally the interchange format should match our semantic object model, not
the way things are laid out in fedora. I see this being addressed in time.
Also, this is another format for which we will need to develop tools to
support.

Q. Ok, enough already, what is the actual format?
A. It uses JSON, so a valid ROF file will also be a valid JSON document. The
reverse is not true, though. These are the restrictions.


  1. A ROF file consists of a top-level JSON array. Each element in the array
is a JSON object.

  2. The only essential property of the object is "type", which indicates the
type of the record. The other fields depend on the type field. Right now there
is only the type "fobject". As the content models are developed, we can add
more types to represent the models.

The "fobject" type represents a basic fedora object. Each "fobject" record
represents a single fedora object. It recognizes the following additional
fields. A star is a wildcard and represents any sequence of characters.

Field       Description
pid         The pid to use for the object. If it includes a prefix, e.g.
            "vecnet:12bc34g", then that is the objects fedora id. It it doesn't
            have a prefix, then the prefix "und:" is added.

rights      The hydra rights of this object. Takes an object. See §Rights below.

rels-ext    The rels-ext data stream of this object. Takes an object.
            See §Rels-ext below.

metadata    Contents for the 'descMetadata' data stream.  Takes an object.
            It is given in JSON-LD, and translated to N3 format to be saved
            into fedora.

*-file      Gives a filename to save as the contents of a data stream given.
            Takes a string. This overwrites the previous content. For example,
            the field 'hello-file' will save the file's contents into the data
            stream 'hello'.

*-meta      Gives the fedora metadata for a given data stream. Takes an object.
            See §Meta below.

*           Assigns the content directly to the named data stream. Takes a string.


# Rights

Rights are given as a object with the keys "discover", "view", "edit". Each key
takes an array of strings. The string "public" and "registered" have special
meaning. Otherwise the strings are taken to be group or user names.

Example:
{"view" : ["public"],
 "edit" : ["dbrower"]
}


# Rels-Ext

Rels-ext are given as an object where each key is a relation, and takes either
an array of strings. The strings are fedora object pids, which indicate which
objects this one is connected to.


Example:
{"isMemberOf" : ["xv57n93k"],
 "relatedTo": ["user:12345"]
}


# Meta
The Metadata field is not for an object's descriptive metadata, rather it is
for the metadata associated to a specific fedora data stream. The data is given
as pairs, the possible pairs are listed below, as well as the defaults. (TODO:
this list is incomplete.)

Field Name  Default         Description
mime-type   "text/plain"    The mime-type of this data stream. The default is
                            adjusted for the special data streams of
                            "descMetadata", "rightsMetadata" and "RELS-EXT".
label       ""              The label for this datastream
versioned   true            Whether this data stream's content is versioned.
storage     "M"             The Fedora storage class of this data stream.
checksum    "SHA-1"         What checksum to use, or empty string to turn off.


# Example ROF File
This is not normative. There are probably errors. The JSON-LD sections are
likely wrong.

[{
     "type" : "fobject",
     "pid" : "vecnet:d217qs82g",
     "class" : "Citation",
     "rights" : {
          "read" : ["public"],
          "edit" : ["vecnet_batchuser"]
          },
     "metadata" : {
          "@context" : "...",
          "id" : "...",
          "dc:title" = "Molecular systematics and insecticide resistance in the major African malaria vector Anopheles funestus",
          "dc:creator" = ["Coetzee, M.", "Koekemoer, L. L."],
          "dc:identifier" = ["doi:10.1146/annurev-ento-120811-153628", "issn:1545-4487 (Electronic)", "issn:0066-4170 (Linking)", "23317045"],
          "dc:description" = "Anopheles funestus is one of three major African vectors of malaria. Its distribution extends over much of the tropics and subtropics wherever suitable swampy breeding habitats are present. As with members of the Anopheles gambiae complex, An. funestus shows marked genetic heterogeneity across its range. Currently, two unnamed species are recognized in the group, with molecular and cytogenetic data indicating that more may be present. The control of malaria vectors in Africa has received increased attention in the past decade with the scaling up of insecticide-treated bed nets and indoor residual house spraying. Also in the past decade, the frequency of insecticide-resistant mosquitoes has increased exponentially. Whether this increase is in response to vector control initiatives or because of insecticide use in agriculture is debatable. In this article we examine the progress made on the systematics of the An. funestus group and review research on insecticide resistance and its mechanisms.",
          "dc:language" = "eng",
          "dc:type" = "Article",
          "dc:source" = "Annual review of entomology",
          "dc:references" = "Molecu2013",
          "dc:bibliographicCitation" = "Annu Rev Entomol 58, 393-412. (2013)",
          "rdf:seeAlso" = "http://www.ncbi.nlm.nih.gov/pubmed/23317045",
          "dc:created" = "2013",
          "dc:modified" = "2014-03-17Z"^^<http://www.w3.org/2001/XMLSchema#date>,
          "rdf:domain" = "Citation"
     },
     "properties-meta" : {
          "mime-type" : "text/xml",
     "properties" : "<fields><depositor>vecnet_batchuser</depositor></fields>"
},
{
     "type" : "fobject",
     "pid" : "vecnet:h415pf50x",
     "class" : "CitationFile",
     "rights" : {
          "read" : ["registered"],
          "edit" : ["vecnet_batchuser"]
     },
     "metadata" : {
          "@context" : "...",
          "id": "...",
         "dc:type" = "CitationFile",
          "dc:dateSubmitted" =  "2014-03-17Z"^^<http://www.w3.org/2001/XMLSchema#date>,
          "dc:modified" = "2014-03-17Z"^^<http://www.w3.org/2001/XMLSchema#date>,
          "dc:creator" = [ "Vecnet Batchuser", "Maureen Coetzee and Lizette L. Koekemoer" ],
          "dc:title" = "Molecular Systematics and Insecticide Resistance in the Major African Malaria Vector Anopheles funestus"
     },
     "rels-ext" : {
          "isPartOf" : ["vecnet:d217qs82g"]
     },
     "properties" : "<fields><depositor>vecnet_batchuser</depositor></fields>",
     "properties-meta" : {
          "mime-type": "text/xml",
          "checksum" : ""
     },
     "content-meta" : {
          "mime-type": "application/pdf",
          "label" : "5772.pdf",
          "checksum": ""
     },
     "content-file" : "/opt/citations/pdf/5772.pdf",
     "full_text-file" : "...",
     "full_text-meta" : {
          "label" : "File Datastream",
          "checksum" : ""
     },
     "characterization-meta" : {
          "mime-type" : "text/xml"
     }
     "thumbnail-meta" : {
          "mime-type" : "image/png",
          "label" : "File Datastream",
          "checksum" : ""
     }
     "thumbnail-file" : "..."
}]



# Extensions
I would call a ROF file containing only "fobjects" and not using labels a
level-0 ROF file. Higher level ROF files would introduce more complicated and
abstract structures, which can ultimately be reduced to a level-0 file by
processing. Then the level-0 file can be directly ingested into Fedora with no
thought whatsoever.

We can even export fedora objects as ROF files. These files would not retain
any previous versions of data streams or the audit history, since ROF does not
capture the entirety of FOXML.
