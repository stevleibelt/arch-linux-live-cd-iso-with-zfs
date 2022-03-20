# Arch Linux Archiso builder with zfs support

This repository contains a simple, free as in freedom, wrapper to automate the steps mentioned in the [arch linux wiki](https://wiki.archlinux.org) for the [zfs installation](https://wiki.archlinux.org/index.php/ZFS#Installation) and the [archios package installation](https://wiki.archlinux.org/index.php/Archiso#Installing_packages).

The current change log can be found [here](CHANGELOG.md).

All you need to do is to execute the [build.sh](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/blob/master/build.sh).

You can download a build iso to use [here](https://archzfs.leibelt.de/).

All needed packages where installed automatically. The build script will output the path to the created iso file.

At the end, you only need to dd the iso to your favorit usb drive, use [venotoy](https://www.ventoy.net) or burn it on an optical disk.

# Howto

```
#build an iso
./build.sh

#test run an existing iso
./run_iso.sh [<string: path to the iso>]

#upload the iso
./upload_iso.sh [<string: path to the iso>]
```

# Links

* [Another archiso build script by Maurice Zhou](https://gitlab.com/m_zhou/archiso)
* [archiso documentation](https://git.archlinux.org/archiso.git/tree/docs)
* [archiso project page](https://git.archlinux.org/archiso.git)
* [pacman wiki page](https://wiki.archlinux.org/index.php/Pacman)

# Contributers

In alphabetically order.

* [gardar](https://github.com/gardar)
* [stevleibelt](https://github.com/stevleibelt)
