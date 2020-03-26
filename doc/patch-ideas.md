
Update/Patch format for CurateND items

A problem with the current ROF implementation is that on ingest the utility assumes the ROF file contains a *complete* representation of an item, and will update the Fedora object so that it matches the ROF file.
This causes problems when trying to only partially update an item.


= Ideas =

Different description of an item: not necessarily json or RDF?
Card based?

As much as i like a card based, i think everyone else will hate it. they will ask why not a standard? like json? is json a standard? card based is more like a csv file, or ntriples.

id 123456
bendo-item asdfdfg:fdsa
dc:title "something here that can be really long\nand will wrap around lines"
file:
 url https://abcda/asdf/asdf
 mime-type application/json
 size 123456
 md5 234nbgf
fd



B 123456
+ B 123456
* B 123456
update B doi:(.*)
with B \1
match B _
add

- M dc:identifier 

= Patch Operations =

- Update a field
- Remove a field
- Add a field
- match a field? (Lets a patch be read as a program?)

wildcard? patterns (regex?)?

field based.




@ und:rr171v56r3d
dc:alternative WIN710-1-3
dc:date#digitized 9/28/2015
dc:dateSubmitted 2018-11-21Z
dc:description "40 on plate. Writing on emulsion"
dc:description#tchnical Epson 11000XL
dc:format#extent 4 in x 5 in
dc:modified: 2018-11-21Z
dc:title Billy Adams 01 (FP in Gym)
frels:isMemberOfCollection und:9306sx6464p
nd:accessEdit grugg
nd:accessEdit mnarlock
nd:accessReadGroup public
nd:afmodel Image
nd:bendoitem r494vh57273
nd:depositor batch_ingest
nd:owner grugg|mnarlock
nd:representativeFile und:rv042r4014k
vracore:length 4 in
vracore:width 5 in
%

remove nd:accessReadGroup "public"
remove nd:accessEdit *
remove nd:accessEdit /bat$/
a nd:accessReadGroup "public"
remove access/readgroup public
add (
  access/edit und:123456
  bendo-item
  owner
  represative-image und:123456
)
on <file>



