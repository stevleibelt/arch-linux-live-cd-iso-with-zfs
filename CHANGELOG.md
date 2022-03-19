# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Open]

### To Add

### To Change

* add option to dd it to a sdX device
* beautify the output
* validate if we can implement the "use older kernel" feature from [here](https://github.com/eoli3n/archiso-zfs/blob/master/init) to prevent failing builds when the archzfs package is not up to date to the latest linux kernel

## [Unreleased]

### Added

* added a [CHANGELOG.md](CHANGELOG.md)
* added list of contributers

### Changed

## [2.0.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.0.0) - released at 07.02.2022

### Added

* added support to run an existing iso
* added usage of pacman-init.service including check of expected content
* added output if iso building is not successful

### Changed

* major rework of internal code - adapted to archiso changes
    * all code is now running into dedicated functions
* aligned output
* moveing the existing iso to $somewhere
* fixed issue with not enough access when generating the checksum files

## [1.3.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/1.3.0) - released at 23.08.2016

### Changed

* implemented user input to select fitting archzfs-linux repository

## [1.2.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/1.2.0) - released at 06.07.2016

### Added

* added automatically renaming each created iso file to archlinux.iso
* added automatically md5sum and sha1sum file creation of created archlinux.iso

## [1.1.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/1.1.0) - released at 14.05.2016

### Added

* added [README.md](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/blob/master/README.md)

### Changed

* renamed "build" directory to "dynamic_data" to ease up execution of "build.sh"

## [1.0.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/1.0.0) - released at 12.05.2016

### Added

* Initial commit
