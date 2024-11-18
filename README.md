# Arch Linux Archiso builder with zfs support

This repository contains a simple, free as in freedom, wrapper to automate the steps mentioned in the [arch linux wiki](https://wiki.archlinux.org) for the [zfs installation](https://wiki.archlinux.org/index.php/ZFS#Installation) and the [archios package installation](https://wiki.archlinux.org/index.php/Archiso#Installing_packages).

The current changelog can be found [here](CHANGELOG.md).

All you need to do is to execute the [build.sh](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/blob/master/build.sh).

You can download a build iso to use [here](https://archzfs.leibelt.de/).

All needed packages where installed automatically. The build script will output the path to the created iso file.

At the end, you only need to dd the iso to your favorit usb drive, use [venotoy](https://www.ventoy.net) or burn it on an optical disk.

[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/badge)](https://securityscorecards.dev/viewer/?uri=github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs)

## Live enviroment

This iso comes with some batteries included.

* [archinstall](https://github.com/archlinux/archinstall) in `/root/software/archinstall` including a `start_archinstall.sh`
* [arch-linux-configuration](https://github.com/stevleibelt/arch-linux-configuration) in `/root/software/arch-linux-configuration`
  * This repository has a [recover](https://github.com/stevleibelt/arch-linux-configuration/tree/master/scripts/zfs/recover) section to ease up fixing broken installations
* [downgrade](https://github.com/pbrisbin/downgrade) to the image in the path `/root/software/downgrade`
  * This repository has a [downgrade](https://github.com/archlinux-downgrade/downgrade/tree/main/bin) executable to ease up downgrade a package
* [general_howtos](https://github.com/stevleibelt/general_howtos) in `/root/document/general_howtos`
  * This repository has an [arch linux](https://github.com/stevleibelt/General_Howtos/tree/master/operation_system/linux/distribution/arch) knowledge section inside
  * This repository has a [unix](https://github.com/stevleibelt/General_Howtos/tree/master/operation_system/unix) knowledge section inside
  * This repository has a [zfs](https://github.com/stevleibelt/General_Howtos/tree/master/filesystem/zfs) knowledge section inside
  * And much more knowledge
* Git
* Vim

## Howto

### Initial setup

```bash
# ref: https://github.com/archzfs/archzfs/wiki#using-the-archzfs-repository
sudo pacman-key -r DDF7DB817396A49B2A2723F7403BD972F75D9D76
sudo pacman-key --lsign-key DDF7DB817396A49B2A2723F7403BD972F75D9D76
```

### Regular buildings

```bash
####
#build an iso
####
#flags
#   -f|--force
#   -d|--dry-run
#   -h|--help
#   -r|--repo-index [<string: last|week|month|yyyy\/mm\/dd>]
#       if you just use -r, default of >>last<< is used
#       @see: https://archive.archlinux.org/repos/
#   -u|--use-dkms
#   -v|--verbose
####
# tired of repeating the same flags again and again?
#
# optional configuration file is supported and saves your keystrokes
# cp configuration/build.sh.dist configuration/build.sh
# adapt file configuration/build.sh
####
./build.sh

#test run an existing iso
./run_iso.sh [<string: path to the iso>]

#upload the iso
./upload_iso.sh [<string: path to the iso>]
```

### Run super-linter locally

```bash
# ref: https://github.com/super-linter/super-linter#run-using-a-container-runtime-engine
#   assuming that . is the path to the local code base
docker run -e LOG_LEVEL=DEBUG -e RUN_LOCAL=true -v .:/tmp/lint ghcr.io/super-linter/super-linter:latest
```

## Possible issues

Following issues are not reproducable on all my machines.

### Error: target not found: ipw2100-fw

* This error happens when calling `build.sh`
* [This](https://gitlab.archlinux.org/archlinux/archiso/-/commit/4d64a58a905403b3abfca5077dcd924ef7901ba7) commit seams to be the reason
* [This](https://bbs.archlinux.org/viewtopic.php?id=279908) thread contins information
* [This](https://forum.endeavouros.com/t/missing-aur-packages-ipw2100-fw-ipw2200-fw/32019) is a solution for endevour os

## Links

* [Another archiso build script by Maurice Zhou: gitlab.com](https://gitlab.com/m_zhou/archiso)
* [archiso documentation: archlinux.org](https://git.archlinux.org/archiso.git/tree/docs)
* [archiso project page: archlinux.org](https://git.archlinux.org/archiso.git)
* [archlinux-lts-zfs: github.com](https://github.com/r-maerz/archlinux-lts-zfs) - 20241118
* [archzfs archive containing each package ever build: archzfs.com](http://archzfs.com/archive_archzfs/) - 20240410
* [Install UEFI and BIOS compatible Arch Linx with encrypted ZFS and ZFSBootMenu by Kayvlim: archlinux.org](https://wiki.archlinux.org/title/User:Kayvlim/Install_UEFI_and_BIOS_compatible_Arch_Linux_with_Encrypted_ZFS_and_ZFSBootMenu#Swap) - 20221108
* [pacman wiki page: archlinux.org](https://wiki.archlinux.org/index.php/Pacman)
* [OpenSSF Scorecard Report: securityscorecards.dev](https://securityscorecards.dev/viewer/?uri=github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs) - 20240408
* [Ubuntu server zfsbootmenu: github.com](https://github.com/Sithuk/ubuntu-server-zfsbootmenu) - 20221108

## Contributers

In alphabetically order.

* [derzahla](https://github.com/derzahla)
  * Updated [sed repro index logic](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/pull/15)
* [gardar](https://github.com/gardar)
  * Added [git workflows](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/pull/11)
* [Kodiman](https://github.com/Kodiman)
  * Added information of the [Ubuntu server zfsbootmenu](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/issues/14)
* [stevleibelt](https://github.com/stevleibelt)
  * Main Developer

