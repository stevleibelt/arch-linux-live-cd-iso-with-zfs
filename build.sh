#!/bin/bash
####
# simple wrapper to automate the steps from
#   https://wiki.archlinux.org/index.php/ZFS#Installation
#
# @author stev leibelt <artodeto@bazzline.net>
# @since 2016-05-09
####

# check if we are root
# check if archiso is installed
# check if we need to clean the build directory

# store current working directory
# cd into build directory
# cp -r /usr/share/archiso/configs/profile/* ~/archlive
# add

echo "[archzfs]\nServer = http://archzfs.com/$repo/x86_64" > archlive/pacman.conf

# mkdir out
# ./build.sh -v
