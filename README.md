# Arch Linux Archiso builder with zfs support

This repository contains a simple, free as in freedom, wrapper to automate the steps mentioned in the [arch linux wiki](https://wiki.archlinux.org) for the [zfs installation](https://wiki.archlinux.org/index.php/ZFS#Installation) and the [archios package installation](https://wiki.archlinux.org/index.php/Archiso#Installing_packages).

All you need to do is to execute the [build.sh](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/blob/master/build.sh).

You have to run the build script as root.

All needed packages where installed automatically. The build script will output the path to the created iso file.

At the end, you only need to dd the iso to your favorit usb drive or burn it on an optical disk.

# Howto

```
#build an iso
./build.sh

#test run an existing iso
./run_iso.sh <string: path to the iso>
```

# Links

* [Another archiso build script by Maurice Zhou](https://gitlab.com/m_zhou/archiso)
* [archiso documentation](https://git.archlinux.org/archiso.git/tree/docs)
* [archiso project page](https://git.archlinux.org/archiso.git)
* [pacman wiki page](https://wiki.archlinux.org/index.php/Pacman)

# History

* upcomming
    * @todo
        * create a CHANGELOG.md
        * beautify the output
        * add option to dd it to a sdX device
* [2.0.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/2.0.0) - released at 07.02.2022
    * major rework of internal code - adapted to archiso changes
        * all code is now running into dedicated functions
    * added support to run an existing iso
    * added usage of pacman-init.service including check of expected content
    * aligned output
    * moveing the existing iso to $somewhere
    * added output if iso building is not successful
    * fixed issue with not enough access when generating the checksum files
* [1.3.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/1.3.0) - released at 23.08.2016
    * implemented user input to select fitting archzfs-linux repository
* [1.2.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/1.2.0) - released at 06.07.2016
    * added automatically renaming each created iso file to archlinux.iso
    * added automatically md5sum and sha1sum file creation of created archlinux.iso
* [1.1.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/1.1.0) - released at 14.05.2016
    * added [README.md](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/blob/master/README.md)
    * renamed "build" directory to "dynamic_data" to ease up execution of "build.sh"
* [1.0.0](https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/tree/1.0.0) - released at 12.05.2016
