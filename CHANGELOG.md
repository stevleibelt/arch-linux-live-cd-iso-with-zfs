# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## Open

### To Add

* Add support for [remove packages](https://wiki.archlinux.org/title/User:LenHuppe/ZFS_on_Archiso/)
* Add usage for `kernel.archzfs.com`
  * [Link](https://end.re/blog/ebp036_archzfs-repo-for-kernels/)
  * [Source](https://github.com/archzfs/archzfs/issues/467#issuecomment-1332029677)
* Add flag `-c|--cleanup` for `build.sh`
* Add an arch installer like:
  * [archinstall](https://github.com/archlinux/archinstall)
  * [anarchy installer](https://anarchyinstaller.gitlab.io/)
  * [alci](https://alci.online/)

### To Change

* Apply [shellcheck](https://github.com/koalaman/shellcheck) to all scripts
* Manipulate `dynamic_dat/releng/profiledef.sh` before running the iso build process
  * [issue/9](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/issues/9)
  * [official profiledef.sh documentation](https://gitlab.archlinux.org/archlinux/archiso/-/blob/master/docs/README.profile.rst)
  * [example of an manipulated file](https://github.com/HougeLangley/archzfs-iso/blob/master/profiledef.sh)
  * Things to change
    * `iso_name`
    * `iso_label`
    * `iso_publisher`
    * `iso_application`
    * `file_permissions`
      * own git repros in user home should have 775
* Recheck GitHub actions using things like [this](https://github.com/ossf/education/pull/36/files) as an example
* Validate if we can implement the "use older kernel" feature from [here](https://github.com/eoli3n/archiso-zfs/blob/master/init) to prevent failing builds when the archzfs package is not up to date to the latest linux kernel

## Unreleased

### Added

* Added content of repository >>https://github.com/ezonakiusagi/bht<< below `software`
* Added packages mailx, ksh and nmon

### Changed

* Changed default values for [replace_zfsbootmenu.sh](source/replace_zfsbootmenu.sh)
  * Default path for old ZBM is now `/mnt/efi...`
  * Default path for new ZBM is now basepath of the called script

## [2.11.1](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.11.1) - 20231111

### Changed

* Fix invalid broken ZFSBootMenu EFI (Portable) downloadpath

## [2.11.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.11.0) - 20231111

### Added

* Added dedicated iso building workflows for
  * `lts_dkms`
  * `lts_no_dkms`
  * `no_lts_dkms`
  * `no_lts_no_dkms`
* Added step to download latest zfsbootmenu.EFI file
* Added script `replace_zfsbootmenu.sh` to ease up updating a system to the latest zfsbootmenu

### Changed

* Change default git workflow job to `linux-lts-dkms`

## [2.10.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.10.0) - 20230526

### Added in 2.10.0

* Added build option to use git package for `zfs-dkms-git` or `zfs-linux-git`
  * Either use `USE_GIT_PACKAGE` in the configuration file
  * Or use `build.sh -g`

## [2.9.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.9.0) - 20230523

### Added in 2.9.0

* Added automatically change of `iso_name` in profiledef.sh
* Added support for `linux-lts` as done [here](https://wiki.archlinux.org/title/User:LenHuppe/ZFS_on_Archiso/), see [here](https://wiki.archlinux.org/title/Archiso#Kernel)
  * Usage: `build.sh -k 'linux-lts'` or `echo KERNEL='linux-lts' > configuration/build.sh`
* Added check if dkms build failed in the `mkarchiso` call by grep'ing the logs - Workaround for [issue/18](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/issues/18)
* Added logging to [build.sh](build.sh) into file `build.sh.log`
* Added `set -e` on [build.sh](build.sh)
* Added [arch-linux-cd-zfs-setup](https://github.com/stevleibelt/arch-linux-live-cd-zfs-setup) to the image path `root/software/arch-linux-live-cd-zfs-setup` - Mostly for debugging and the case when neither zfs-dkms nor zfs-linux is compatible with the current/latest linux kernel [e.g. see [here](https://github.com/archzfs/archzfs/issues/486)]
* Added [scorecard](https://github.com/marketplace/actions/ossf-scorecard-action) GitHub action
* Added explicit and dedicated function `_remove_file_path_or_exit`

### Changed in 2.9.0

* Changed number of available iso file check from "greater 0" to "equal 1"
* Changed place where `last_build_date.txt` is created, moved from [upload_iso.sh](upload_iso.sh) to [build.sh](build.sh)
* Updated [upload_iso.sh](upload_iso.sh) to meet the [shellcheck](https://www.shellcheck.net/)
* Updated workflow and added step that creates `configuration/build.sh`

## [2.8.1](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.8.1) - 20230129

### Changed in 2.8.1

* Updated [sed repro index logic](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/pull/15)

## [2.8.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.8.0) - 20230129

### Added in 2.8.0

* Added configuration option `ASK_TO_DUMP_ISO`, `ASK_TO_RUN_ISO` and `ASK_TO_UPLOAD_ISO`
* Added git repository [arch-linux-configuration](https://github.com/stevleibelt/arch-linux-configuration) to the image in the path `/root/software/arch-linux-configuration`
* Added git repository [downgrade](https://github.com/pbrisbin/downgrade) to the image in the path `/root/software/downgrade`
* Added git repository [general_howtos](https://github.com/stevleibelt/general_howtos) to the image in path `/root/document/general_howtos`

### Changed in 2.8.0

* Fixed not working [run_iso.sh](run_iso.sh)

## [2.7.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.7.0) - 20230111

### Added in 2.7.0

* Added `touch` to update creation date of `last_build_date.txt`
* Added `git` as mandatory package to ease up using [arch-linux-configuration](https://github.com/stevleibelt/arch-linux-configuration)
* Added "possible errors" section in the readme
* Added flag `-u|--use-dkms` to use `zfs-dkms` instead of `zfs-linux`

### Changed in 2.7.0

* Changed some of the `_echo_if_be_verbose` calls by adding the variable name before outputing its content`
* Added removal of `last_build_date.txt` if exists when `upload_iso.sh` is executed
* Updated `source/pacman-init.service`
* Moved from `qemu` to `qemu-full`

## [2.6.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.6.0) - 20220419

### Changed in 2.6.0

* Fixed [issue/8](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/issues/8)

## [2.5.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.5.0) - 20220418

### Added in 2.5.0

* Added `-d`, `-h` and `-v` to `upload_iso.sh`
* Implemented code from [pull request/6](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/pull/6) with an additional flag "-r|--repo-index <string: last|week|month|yyyy/mm/dd>"
  * If you just provide `-r`, `week` is used
* Added [configuration file](configuration/build.sh.dist) for build.sh
* Added `-d|--dry-run` in `build.sh`

### Changed in 2.5.0

* Remove usage of `BE_VERBOSE` in `configuration/upload_iso.sh` since this is superseeded by `-v`

## [2.4.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.4.0) - released at 20220330

### Added in 2.4.0

* Added if `[[ ${?} -ne 0 ]];` for each fitting command call
* Added [dump_iso.sh](dump_iso.sh) to dd a created iso
* Added check if build was successful
  * The next steps where only executed if build was successful
* Added output of flags when verbosity is enabled
* Added way more output if run in verbose mode
* Added addtional check in the step after bulding the iso to validate that an iso was build
* Added doc block to each function
* Added argument check in each function

### Changed in 2.4.0

* Fixed an issue if script is not calld as root
  * Previous to this fix, all arguments where lost (like `-f`)
* Centralized code by creating `_create_directory_of_exit` an `_remove_path_or_exit`

## [2.3.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.3.0) - released at 20220328

### Added 2.3.0

* Added flag `-h | --help`
* Added flag `-f | --force`
* Added flag `-v | --verbose`

## [2.2.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.2.0) - released at 20220320

### Added 2.2.0

* added the `auto_elevate_if_not_called_from_root` from [build.sh](build.sh) in [run_iso.sh](run_iso.sh)
* added [upload_iso.sh](upload_iso.sh)
  * if not available, it creates a local configuration file in [configuration](configuration)
  * if user says yes, this is executed after a successful [build.sh](build.sh)
* created [archzfs.stevleibelt.de](https://archzfs.leibelt.de/)

### Changed in 2.2.0

* Aligned release date
* Fixed link in release 2.1.0

## [2.1.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.1.0) - released at 20220319

### Added in 2.1.0

* added a [CHANGELOG.md](CHANGELOG.md)
* added list of contributers

### Changed in 2.1.0

* replaced current handlig of "exit if not executed from root" with "restart script by using sudo if not executed from root" - thanks to [gardar](https://github.com/gardar)

## [2.0.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.0.0) - released at 20220207

### Added in 2.0.0

* added support to run an existing iso
* added usage of pacman-init.service including check of expected content
* added output if iso building is not successful

### Changed in 2.0.0

* major rework of internal code - adapted to archiso changes
  * all code is now running into dedicated functions
* aligned output
* moveing the existing iso to $somewhere
* fixed issue with not enough access when generating the checksum files

## [1.3.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/1.3.0) - released at 20160823

### Changed in 1.3.0

* implemented user input to select fitting archzfs-linux repository

## [1.2.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/1.2.0) - released at 20160706

### Added in 1.2.0

* added automatically renaming each created iso file to archlinux.iso
* added automatically md5sum and sha1sum file creation of created archlinux.iso

## [1.1.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/1.1.0) - released at 20160514

### Added in 1.1.0

* added [README.md](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/blob/master/README.md)

### Changed in 1.1.0

* renamed "build" directory to "dynamic_data" to ease up execution of "build.sh"

## [1.0.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/1.0.0) - released at 20160512

### Added in 1.0.0

* initial commit
