BDiff / BPatch
==============

Binary diff and patch programs for the Windows command line.

Introduction
------------

_BDiff_ computes differences between two binary files. Output can be either a somewhat human-readable protocol in plain text, or a binary file that is readable by _BPatch_.

_BPatch_ applies a binary patch generated by _BDiff_ to a file to recreate the original file.

See the files `BDiff.txt` and `BPatch.txt` for details of how to use the programs.

_BDiff_ and _BPatch_ are derived from Stefan Reuther's _bdiff_ and _bpatch_ v0.2 and a later bug fix by Stefan.

The original C source was translated into Object Pascal by Peter D Johnson ([@delphdabbler](https://twitter.com/delphidabbler)). The programs are are based on updates of the Pascal code base.

The programs should run on any current version of Windows.

For more information see the see the [project web pages](http://delphidabbler.com/software/bdiff).

Installation
------------

Copy the provided executable files to the required location. No further installation is required.

You may want to modify the Windows PATH environment variable to include the location of the programs.

To uninstall simply delete the programs. They make no changes to the system. If you changed the PATH environment variable you may wish to adjust this.

Source Code
-----------

### Pascal Source

The current source code is maintained in the [delphidabbler/bdiff](https://github.com/delphidabbler/bdiff) Git repository on GitHub. It contains releases going back to v0.2.5. Earlier versions were not under version control and are no longer available.

> **Note:** Until February 2014 the source code was maintained in a [Subversion repository](https://www.assembla.com/code/bdiff/subversion/nodes) on assembla.com. This repo remains in place for the time being, but is no longer being updated.

For information on how to build the Pascal source, see `Build.txt` in the root of the Git repo.

### C Source

The original C source code can be downloaded from http://phost.de/~stefan/Files/bdiff-02.zip.

The copy used for the original Pascal translation is included in the Git repository.

Copyright and License
---------------------

See the file `LICENSE.md` for details of copyright and the license that applies to this software. The license can also be found at http://www.delphidabbler.com/software/bdiff/license.

The original C source is provided under different licensing terms. For details see the comments in the ADMINISTRATIVIA section of `bdiff.1` and `bpatch.1` that are located with the C source code in the Subversion repository.

Change Log
----------

The change log is provided in the file `ChangeLog.txt`.

