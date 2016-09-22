ROF Profiles and Validation
===========================

A ROF file is, at a minimum, a JSON file consisting of an array of objects.
ROF files are used as the intermediate language to pass structured information between the batch ingest tasks.
Since ROF files are used for many purposes, it is not useful to give a single description for all of them.
However, since ROF files are now stored in our tape system, it is necessary to define a *ROF profile* and what it means for an ROF file to *conform to a ROF profile*.

# ROF Profiles

A *ROF profile* defines a subset of all possible ROF files.
A ROF file is said to conform to a given profile if it is a member of the profile.
For the most part we will not list every individual member of a profile, but rather will
describe the profile in some way.

## The *Triple Schema* description of a profile
One way to describe a profile is as a tuple (J, M, R)
where *J* is JSON blob consisting of a JSON-Schema schema,
and both *M* and *J* are RDF graphs containing a SHACL shape graph.
An ROF file is a member of a profile (J, M, R) if and only if all the following hold:

 * The entire ROF file validates against the json schema *J*,
 * Any metadata sections validate against the SHACL shape graph *M*,
 * Any rels-ext sections validate against the SHACL shape graph *R*.

Not all profiles can be described this way (e.g. a profile where only prime numbers can be used to identify objects).
Nevertheless, we expect it to describe most profiles that we care about, and in particular we can use it to describe the preservation profile.

# Preservation profile

We will create a preservation profile for ROF files we will be storing on tape.
