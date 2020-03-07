# Introduction to ROF

ROF was designed to be a way to serialize a Fedora 3 object in a way that we
could create and update it with simple tools before loading it into Fedora.
This means ROF objects are very tightly coupled with their corresponding F3
targets: they represent the same datastream layout, and they have the ability
to represent arbitrary F3 data.

(If you need to move arbitrary F3 objects, look at ndlib/f3cp).

However, in practice we only ever used ROF to represent CurateND objects,
which have a much simpler structure. It has also been awkward to work with
CurateND objects represented as ROF since sometimes data is duplicated
between the datastreams (e.g. rightsMetadata and RELS-EXT), and each
datastream has wildly different formats: plain text, XML, RDF as NTriples,
and RDF as XML.

It is hard to canonicalize an ROF representation of an object to facilitate
comparison between two for changes (this is largely because we represent the
RELS-EXT and metadata datastreams as JSON-LD, which doesn't have a canonical
representation).

Another issue is one of validation: it is very difficult to validate an ROF
item to handle specific CurateND requirements. The ROF validate step as
currently written only checks for the most basic of problems at a general ROF
level.

## In this directory

* [flat.md] Is a proposal for a better format to represent CurateND objects
* [curatend.md] Is a HOW-TO for some common tasks.
