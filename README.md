# Arch Linux Archiso builder with zfs support

This repository contains a simple, free as in freedom, wrapper to automate the steps mentioned in the [arch linux wiki](https://wiki.archlinux.org) for the [zfs installation](https://wiki.archlinux.org/index.php/ZFS#Installation) and the [archios package installation](https://wiki.archlinux.org/index.php/Archiso#Installing_packages).

The current change log can be found [here](CHANGELOG.md).

All you need to do is to execute the [build.sh](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/blob/master/build.sh).

You can download a build iso to use [here](https://archzfs.leibelt.de/).

All needed packages where installed automatically. The build script will output the path to the created iso file.

At the end, you only need to dd the iso to your favorit usb drive, use [venotoy](https://www.ventoy.net) or burn it on an optical disk.

## Howto

```
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

## Links

* [Another archiso build script by Maurice Zhou](https://gitlab.com/m_zhou/archiso)
* [archiso documentation](https://git.archlinux.org/archiso.git/tree/docs)
* [archiso project page](https://git.archlinux.org/archiso.git)
* [pacman wiki page](https://wiki.archlinux.org/index.php/Pacman)
* [Ubuntu server zfsbootmenu](https://github.com/Sithuk/ubuntu-server-zfsbootmenu)

## Contributers

In alphabetically order.

* [derzahla](https://github.com/derzahla)
* [gardar](https://github.com/gardar)
  * Added [git workflows](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/pull/11)
* [Kodiman](https://github.com/Kodiman)
  * Added information of the [Ubuntu server zfsbootmenu](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/issues/14)
* [stevleibelt](https://github.com/stevleibelt)
  * Main Developer

