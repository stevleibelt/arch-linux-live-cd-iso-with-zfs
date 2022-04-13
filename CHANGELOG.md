# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Open]

### To Add

### To Change

* add flags for `build.sh`
    * `-c` - cleanup
* validate if we can implement the "use older kernel" feature from [here](https://github.com/eoli3n/archiso-zfs/blob/master/init) to prevent failing builds when the archzfs package is not up to date to the latest linux kernel
* add an arch installer like [archinstall](https://github.com/archlinux/archinstall), [anarchy installer](https://anarchyinstaller.gitlab.io/) or [alci](https://alci.online/)

## [Unreleased]

### Added

* Implemented code from [pull request/6](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/pull/6) with an additional flag "-r|--repo-index <string: last|week|month|yyyy/mm/dd>"
* Added [configuration file](configuration/build.sh.dist) for build.sh

### Changed

## [2.5.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.5.0) - not yet released

### Added

* Added `-d`, `-h` and `-v` to `upload_iso.sh`
* Added flag `-l|--last-week` or `-w|--week-older` as discussed in [pull/6](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/pull/6) - @todo
    * Check the [archive](https://archive.archlinux.org/repos/)
    * What about `-l|--last {week|month|yyyy/mm/dd}`
    * Yo can find the right place [here](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/pull/6/files)

### Changed

* Remove usage of `BE_VERBOSE` in `configuration/upload_iso.sh` since this is superseeded by `-v`

## [2.4.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.4.0) - released at 20220330

### Added

* Added if [[ ${?} -ne 0 ]]; for each fitting command call
* Added [dump_iso.sh](dump_iso.sh) to dd a created iso
* Added check if build was successful
    * The next steps where only executed if build was successful
* Added output of flags when verbosity is enabled
* Added way more output if run in verbose mode
* Added addtional check in the step after bulding the iso to validate that an iso was build
* Added doc block to each function
* Added argument check in each function

### Changed

* Fixed an issue if script is not calld as root
    * Previous to this fix, all arguments where lost (like `-f`)
* Centralized code by creating `_create_directory_of_exit` an `_remove_path_or_exit`

## [2.3.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.3.0) - released at 20220328

### Added

* Added flag `-h | --help`
* Added flag `-f | --force`
* Added flag `-v | --verbose`

## [2.2.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.2.0) - released at 20220320

### Added

* added the `auto_elevate_if_not_called_from_root` from [build.sh](build.sh) in [run_iso.sh](run_iso.sh)
* added [upload_iso.sh](upload_iso.sh)
    * if not available, it creates a local configuration file in [configuration](configuration)
    * if user says yes, this is executed after a successful [build.sh](build.sh)
* created [archzfs.stevleibelt.de](https://archzfs.leibelt.de/)

### Changed

* Aligned release date
* Fixed link in release 2.1.0

## [2.1.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.1.0) - released at 20220319

### Added

* added a [CHANGELOG.md](CHANGELOG.md)
* added list of contributers

### Changed

* replaced current handlig of "exit if not executed from root" with "restart script by using sudo if not executed from root" - thanks to [gardar](https://github.com/gardar)

## [2.0.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.0.0) - released at 20220207

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

## [1.3.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/1.3.0) - released at 20160823

### Changed

* implemented user input to select fitting archzfs-linux repository

## [1.2.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/1.2.0) - released at 20160706

### Added

* added automatically renaming each created iso file to archlinux.iso
* added automatically md5sum and sha1sum file creation of created archlinux.iso

## [1.1.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/1.1.0) - released at 20160514

### Added

* added [README.md](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/blob/master/README.md)

### Changed

* renamed "build" directory to "dynamic_data" to ease up execution of "build.sh"

## [1.0.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/1.0.0) - released at 20160512

### Added

* initial commit
