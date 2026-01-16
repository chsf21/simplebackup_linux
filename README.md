# simple_backup_linux
A simple backup script written in bash. This is not intended to be a complete and polished backup solution; it is just a script that I wrote for myself to make backups simply. Therefore customization is mostly done through modifying the source code of the script.

## Requires
* bash
* A UNIX-like file system

## Overview
* Support for backing up to multiple drives (specified by the user upon running the program normally) (These are **not** passed as command line arguments)
* A list of directories to be backed up are to be specified in the source code (at the top of the file in the array backup_dirs. To backup just the home folder, place ~/ in backup_dirs). These will be saved as compressed tar.gz archives in a directory on the backup drive (the name of the directory will be the current date and time).
* Some directories may be "synced" using rsync instead of being backed up as tar.gz files. These should be also specified in the source code. Simply edit the code in the function backing_up. (Please read through the source code in order to understand how a directory can be added or removed from the list of directories to be synced)
