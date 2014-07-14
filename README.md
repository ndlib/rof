# Raw Object Format

[![Gem Version](https://badge.fury.io/rb/rof.png)](http://badge.fury.io/rb/rof)

This is a pilot project to produce an intermediate data format that makes the
bulk ingest of data into the Fedora Commons repository software simple. While the goal
is to provide as simple of a format as possible, some affordances are made for
defining standard datastreams used by Hydra project front-ends, such as the
`rightsMetadata` datastream.

See `spec/fixtures/vecnet-citation.json` as a sample two object model.
An overview of the format is in [bulk-ingest.md](bulk-ingest.md).

Sample command line usage:

```
$ bin/rof --fedora 'http://localhost:8983/fedora' --user fedoraAdmin:fedoraAdmin spec/fixtures/vecnet-citation.json
1. Ingesting vecnet:d217qs82g ...ok. 0.882s
2. Ingesting vecnet:h415pf50x ...ok. 0.283s
Total time 1.165s
0 errors
```

ROF does more than just ingesting.
Should an object already exist in Fedora, it will be updated to match what is provided in the source file.
(However, this only applies to datastreams which are mentioned in the source file. Unmentioned datastreams
are untouched).

If the fedora path and user are omitted then rof lints the json file.

```
$ bin/rof spec/fixtures/vecnet-citation.json
1. Verifying vecnet:d217qs82g ...ok. 0.108s
2. Verifying vecnet:h415pf50x ...ok. 0.002s
Total time 0.111s
0 errors
```

It is envisioned that there could be higher level objects, and that the ingesting into fedora done by this utility
will be simply the final step of many.
Other ideas for transformations:

* A service to assign a pid to every object not having one. A notion of *labels* could be used
to allow for linking between objects before having a pid.
* A service to expand higher-level objects, say an `image-collection`, into a sequence of `fobjects`.
* The ability to run file characterizations and create derivatives before ingest.
