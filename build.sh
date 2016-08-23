#!/bin/bash
####
# simple wrapper to automate the steps from
#   https://wiki.archlinux.org/index.php/ZFS#Installation
#   and
#   https://wiki.archlinux.org/index.php/Archiso#Installing_packages
#
# @author stev leibelt <artodeto@bazzline.net>
# @since 2016-05-09
####

#begin of variables declaration

LOCAL_CURRENT_WORKING_DIRECTORY=$(pwd)
LOCAL_PREFIX_FOR_EXECUTING_COMMAND="sudo "
LOCAL_PATH_OF_THIS_FILE=$(cd $(dirname "${BASH_SOURCE[0]}"); pwd)
LOCAL_PATH_TO_THE_DYNAMIC_DATA_DIRECTORY="$LOCAL_PATH_OF_THIS_FILE/dynamic_data"
LOCAL_PATH_TO_THE_OUTPUT_DIRECTORY="$LOCAL_PATH_TO_THE_DYNAMIC_DATA_DIRECTORY/out"
LOCAL_PATH_TO_THE_PROFILE_DIRECTORY="/usr/share/archiso/configs/releng"
LOCAL_WHO_AM_I=$(whoami)

#end of variables declaration

#begin of check if we are root

if [[ $LOCAL_WHO_AM_I = "root" ]];
then
    PREFIX_FOR_EXECUTING_COMMAND=""
fi

#end of check if we are root

#begin of check if archiso is installed

if [[ ! -d $LOCAL_PATH_TO_THE_PROFILE_DIRECTORY ]];
then
    echo "no archiso package installed so far, we are going to install it now."
    $LOCAL_PREFIX_FOR_EXECUTING_COMMAND pacman -Syu archiso
fi

#end of check if archiso is installed

#begin of dynamic data directory exists

if [[ -d $LOCAL_PATH_TO_THE_DYNAMIC_DATA_DIRECTORY ]];
then
    LOCAL_DIRECTORY_IS_NOT_EMPTY="$(ls -A $LOCAL_PATH_TO_THE_DYNAMIC_DATA_DIRECTORY)"

    if [[ $LOCAL_DIRECTORY_IS_NOT_EMPTY ]];
    then
        echo "we need to cleanup the directory: $LOCAL_PATH_TO_THE_DYNAMIC_DATA_DIRECTORY"
        $LOCAL_PREFIX_FOR_EXECUTING_COMMAND rm -fr $LOCAL_PATH_TO_THE_DYNAMIC_DATA_DIRECTORY/*
    fi
else
    mkdir -p $LOCAL_PATH_TO_THE_DYNAMIC_DATA_DIRECTORY
fi

#end of dynamic data directory exists

#begin of creating the output directory

mkdir -p $LOCAL_PATH_TO_THE_OUTPUT_DIRECTORY

#end of creating the output directory

#begin of copying needed profile

cp -r $LOCAL_PATH_TO_THE_PROFILE_DIRECTORY/* $LOCAL_PATH_TO_THE_DYNAMIC_DATA_DIRECTORY

#end of copying needed profile

#begin of user interaction
#@todo ask what kind of archzfs the user wants to use:
#   archzfs-linux (default)
#   archzfs-linux-git
#   archzfs-linux-lts
echo ":: There are 3 archzfs repositories available:"
echo ":: Repositories"
#echo "   1) archzfs-linux  2) archzfs-linux-git  3) archzfs-linux-lts"
echo "   1) archzfs-linux  2) archzfs-linux-git"
echo ""
read -p "   Enter a selection (default=1): " LOCAL_SELECTED_ARCHZFS_REPOSITORY
#end of user interaction

#begin of adding archzfs repository and package

echo "[archzfs]" >> $LOCAL_PATH_TO_THE_DYNAMIC_DATA_DIRECTORY/pacman.conf
echo "Server = http://archzfs.com/\$repo/x86_64" >> $LOCAL_PATH_TO_THE_DYNAMIC_DATA_DIRECTORY/pacman.conf
case $LOCAL_SELECTED_ARCHZFS_REPOSITORY in
    2 )
        echo "archzfs-linux-git" >> $LOCAL_PATH_TO_THE_DYNAMIC_DATA_DIRECTORY/packages.x86_64
        ;;
    3 )
#@todo begin of support for lts
#@idea (uname -r | grep lts)?
#@see:
#   https://wiki.archlinux.org/index.php/Pacman -> IgnorePkg
#   https://blog.chendry.org/2015/02/06/automating-arch-linux-installation.html
        echo "linux-lts" >> $LOCAL_PATH_TO_THE_DYNAMIC_DATA_DIRECTORY/packages.both
        echo "archzfs-linux-lts" >> $LOCAL_PATH_TO_THE_DYNAMIC_DATA_DIRECTORY/packages.x86_64
        ;;
#@todo end of support for lts
    *)
        echo "archzfs-linux" >> $LOCAL_PATH_TO_THE_DYNAMIC_DATA_DIRECTORY/packages.x86_64
        ;;
esac

#end of adding archzfs repository and package

#begin of building

cd $LOCAL_PATH_TO_THE_DYNAMIC_DATA_DIRECTORY

$LOCAL_PREFIX_FOR_EXECUTING_COMMAND ./build.sh -v

#end of building

#begin of renaming and hash generation
cd $LOCAL_PATH_TO_THE_OUTPUT_DIRECTORY
mv archlinux*.iso archlinux.iso
sha1sum archlinux.iso > archlinux.iso.sha1sum
md5sum archlinux.iso > archlinux.iso.md5sum
#end of renaming and hash generation

#@todo
#ask if we should dd this to a sdx device

echo "iso created in:"
echo "    $LOCAL_PATH_TO_THE_OUTPUT_DIRECTORY"
echo "--------"

ls -halt $LOCAL_PATH_TO_THE_OUTPUT_DIRECTORY

cd $LOCAL_CURRENT_WORKING_DIRECTORY
