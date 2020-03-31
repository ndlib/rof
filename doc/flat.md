# Flat Records

Flat is a format for representing CurateND objects. It is essentially an
local identifier (PID) and a list of key-value pairs, where keys may be
repeated. Both keys and values are strings.

Most transformations and validations in the ROF gem use the flat record
as the internal representation of a CurateND item.

## Key Ordering

The ordering of keys is not important except for repeated keys, in which case
the relative ordering of the repeated keys is important, and should be
preserved.

## Blank Nodes

If data with one-level of blank nodes needs to be represented, the double-caret
encoding is used to flatten the blank node to a string, and that string is stored
as the value. "one-level of blank nodes" means that the main object has a property

## Serialization

There is no serialization format for flat records---yet! For now all the formats--
rof, csv, jsonld, etc--are converted into flat records internally, and then serialized
back out when the transformations are finished. This suggests our guiding principle:

   It should be possible to round-trip from rof to flat records and back without the
   loss of any information.

# Field Names

In the following,
(=1) means there should be exactly one value for this field, and it shoud be present;
(*1) means item is optional, but there is at most one entry if present;
(0+) means the item is multi-valued and optional.
Fields marked with an asterisk `*` are used for internal processing only.

  Field                 | Description
  -----                 | -----------
  af-model              | The ActiveFedora Model of this object (=1)
  bendo-item            | The bendo item for this object (*1)
  depositor             | The netid of the depositor of this object (=1)
  discover-group        | PID or netid of group having discover rights (0+)
  discover-person       | PID or netid of person having discover rights (0+)
  depositor             | Netid of person depositing this record (=1)
  edit-group            | PID or netid of group having edit rights (0+)
  edit-person           | PID or netid of person having edit rights (0+)
  embargo-date          | Embargo date in YYYY-MM-DD (*1)
  file-url              | URL to file contents, probably bendo (*1)
  file-md5              | MD5 Checksum of the content as lowercase hex, if there is content file (*1)
  file-mime-type        | Mime type of file contents, only if content file (*1)
  filename              | Base name of the file, if content file (*1)
  isMemberOfCollection  | PID of collection this object belongs to (0+)
  isPartOf              | PID of object this is a file of (*1)
  owner                 | The netid of the "owner" of this object (=1)
  pid                   | The PID of this record (und:xxxx) (*1)
  read-group            | PID or netid of group having read rights (0+)
  read-person           | PID or netid of person having read rights (0+)
  representative        | PID of a representative image for this object (*1)
  rof-type              | The ROF type field (=1)
  thumbnail             | URL of thumbnail (? not sure how internal fedora desc look) (*1)
  files *               | List of files that are a part of this work. (0+)
  file-path *           | relative path to a file to upload (*1)
