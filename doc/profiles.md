ROF Profiles and Validation
===========================

A ROF file is, at a minimum, a JSON file consisting of an array of objects.
ROF files are used as the intermediate language to pass structured information between the batch ingest tasks.
Since ROF files are used for many purposes, it is not useful to give a single description for all of them.
However, since ROF files are now stored in our tape system, it is necessary to define a *ROF profile* and what it means for an ROF file to *conform to a ROF profile*.

# ROF Profiles

A *ROF profile* defines a subset of all possible ROF files.
A ROF file is said to *conform* to a given profile if it is a member of the profile.

Our first attempt to describe a ROF profile is with a tuple (J, M, R)
where *J* is JSON blob consisting of a [JSON-Schema](http://json-schema.org/) schema,
and both *M* and *J* are RDF graphs containing a [SHACL](https://www.w3.org/TR/shacl/) shape graph.
An ROF file is a member of the profile *(J, M, R)* if and only if all the following hold:

 * The entire ROF file validates against the json schema *J*,
 * All `metadata` sections validate individually against the SHACL shape graph *M*,
 * All `rels-ext` sections validate individually against the SHACL shape graph *R*.

Not all profiles can be described this way (e.g. a profile where only prime numbers can be used to identify objects).
Nevertheless, we expect it to describe most profiles that we care about, and in particular we can use it to describe the preservation profile.

# Preservation profile

We will create a preservation profile for ROF files we will be storing on tape.
The profile is intended to be fairly strict.
The following list is not intended to be authoritative---for an authoritative source look at the various schema files.

 1. The file consists of a JSON array containing 0 or more JSON objects
 1. Each object must contain an entry for a `pid`, `type`, `af-model`, `rels-ext`, `rights`, and `metadata`.
 1. The `type` property must equal `"fobject"`.
 
There is not a SHACL implementation for ruby-rdf yet, but when there is more validation will be done.

 1. The RDF graphs will use identifiers in the form `und:XXXXX` to refer to curate objects.
 1. The content URLs will use a URL in the form `bendo:XXXXX/YYYYY` to refer to items in bendo.
