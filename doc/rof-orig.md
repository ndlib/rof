Batch Ingest SIP format

It should handle the following use cases at a minimum:

 * Creation of a new item with the given file tree
 * Adding more files to a given item
 * Updating the metadata for a given item
 * Updating some files for a given item

There may be predefined item types which can make entering some types of items
more efficient.


 * Create a new work with some metadata and a list of attached files:


    work {
        bundle:
        id: $(variable)
        af-model:
        metadata:
        read-group:
        read-person:
        edit-person:
        depositor:
        owner:
        files:
            - a.txt, mime-type: "text/plain"
            - b.txt, mime-type: "application/pdf"
            - c.txt, mime-type: "application/octet-stream"
            - d.txt, mime-type: "text/html"
    }

OR if there are a list of works in a given directory

    work{ ... }
    work{ ... }
    work{ ... }

by default a new item is created. but we can use an existing one:

    item XXXXX

This will add any extra files into that item.
If we want to replace the contents of the item completely:

    item XXXXX replace



* To update the metadata for a already uploaded work:

    work XXXXX { ... }

* To update every work inside an item? (e.g. for permissions or to set a collection?)

* To Add a file to an existing work


Common constellations?

 - Object with attached files.





The ultimate upload to bendo will transfer a directory using the bendo stub
file convention. (stub file convention:

 * if a file is present and has length > 0, then it is uploaded if different
   from the previous version
 * if a file has length 0, it is ignored, and no change is made to it on the
   server.
 * if a file which was present is no longer present, it is "removed" from the
   newest version of the item on the server.

Also, to rename a file, it is necessary to download it, and then rename the
file on the filesystem. The upload tool will then detect the rename, and won't
re-upload it.
)

There will be one upload directory per bundle. Each such directory can contain
many fedora works.

These directories can be created by hand, or they can be created using the ROF
tool. A ROF file describes the intended fedora objects and the files it is
desired to put into the bundle. The ROF tool will follow its own conventions on
how to organize the directories, not because it is necessary but to make the
tool configuration simplier.

At the highest level, it is possible to provide a CSV file which will be
translated into a ROF file (and in turn, into the directories).

## Description of stub-file upload

Any directories with the name "bundle-XXXXXX" will be uploaded to the bendo
item XXXXXX. The bendo server to upload to needs to be passed in.

## Description of ROF file

A ROF file describes the logical structure of the items, and will be turned
into a number of NTriple files by the ROF tool. So it does two things: Arrange
files into a hierarchy and create NT files describing the fedora objects.

A ROF file can give: the bundle name to use; the work ids to use; metadata to
use (either directly, or use external files); the files to place in the bundle;
and the files to attach to works. It can also specify whether the metadata is
to be PATCHed or REPLACED.

ROF commands:

    (add | modify | replace) item XXXXX {
        files:
            - a.txt
            - b.txt to stuff/b.txt
            - PROG045/Extra.pdf to stuff/Extra.pdf
    }

This will add files into an item. These are files which are not associated to a
fedora object. (any files associated with fedora objects are added into the
subdirectory YYYYY/file_name, where YYYY is the fedora id for the file. TODO:
change this)

    (add | modify | replace) work XXXXXX {
        bundle:
        id: $(variable)
        af-model:
        read-group:
        read-person:
        write-group:
        write-person:
        depositor:
        owner:
        property: value
        files:
            - a.txt
            - b.txt with mime-type "text/plain"
            - c.txt to stuff/c.txt with mime-type "text/plain" label "contrasts.txt"
            - at stuff/Extra.pdf with mime-type "application/pdf"
            - file { e.jpg with access "private" }
    }

This will generate a curatend "work" object. The work is first checked to see
if it already exists in fedora, if so the bundle id for it is fetched.
Otherwise the bundle id of the last item in the ROF file is used (and a new one
is created if there is no prior item in the ROF).

change work {
    id: XXXXX
    bundle: YYYYY
    remove {
    }
    add {
        file:
            - a.txt
    }
}


output file:
Date                Status  OK What    CurateID    BendoID                     Title
2016/02/10 10:12:33 UPDATED O. file                123456/INFO.txt
2016/02/10 10:12:33 ADDED   OK file    ty34ws77d   123456/orig/a.txt           a.txt
2016/02/10 10:12:33 PATCHED OK work    hx45jk30r   123456/fedora3/hx45jk30r.nt Analysis of future projects (2016)
2016/02/10 10:12:33 ADDED   OK file                123456/fedora3/ty34ws77d.nt
2016/02/10 10:12:34 ADDED   OK file                123456/fedora3/kk89b456h.nt
2016/02/10 10:12:35 PATCHED OK collect kk89b456h   87tk45/fedora3/87tk45.nt    The Dogcow Project


Status:
    ADDED = uploaded new file
    UPDATED = replaced file with a new version
    PATCHED = patched a fedora nt file (special case of UPDATED)

OK:
    OK = uploaded to bendo AND fedora
    O. = only uploaded to bendo, nothing to upload to fedora
    O* = upload to bendo successful, upload to fedora had error
    ** = upload to bendo unsuccessful
