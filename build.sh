#!/bin/bash
####
# simple wrapper to automate the steps from
#   https://wiki.archlinux.org/index.php/ZFS#Installation
#
# @author stev leibelt <artodeto@bazzline.net>
# @since 2016-05-09
####

# begin of variables declaration

LOCAL_CURRENT_WORKING_DIRECTORY=$(pwd)
LOCAL_PREFIX_FOR_EXECUTING_COMMAND="sudo "
LOCAL_PATH_OF_THIS_FILE=$(cd $(dirname "${BASH_SOURCE[0]}"); pwd)
LOCAL_PATH_TO_THE_BUILD_DIRECTORY="$LOCAL_PATH_OF_THIS_FILE/build"
LOCAL_PATH_TO_THE_OUTPUT_DIRECTORY="$LOCAL_PATH_TO_THE_BUILD_DIRECTORY/out"
LOCAL_PATH_TO_THE_PROFILE_DIRECTORY="/usr/share/archiso/configs/releng"
LOCAL_WHO_AM_I=$(whoami)

# end of variables declaration

# begin of check if we are root

if [[ $LOCAL_WHO_AM_I = "root" ]];
then
    PREFIX_FOR_EXECUTING_COMMAND=""
fi

# end of check if we are root

# begin of check if archiso is installed

if [[ ! -d $LOCAL_PATH_TO_THE_PROFILE ]];
then
    echo "no archiso package installed so far, we are going to install it now."
    #@todo
    $LOCAL_PREFIX_FOR_EXECUTING_COMMAND"pacman -Syu archiso"
fi

# end of check if archiso is installed

# begin of build directory is empty

if [[ -d $LOCAL_PATH_TO_THE_BUILD_DIRECTORY ]];
then
    LOCAL_DIRECTORY_IS_NOT_EMPTY="$(ls -A $LOCAL_PATH_TO_THE_BUILD_DIRECTORY)"
    #@todo
    echo $LOCAL_PATH_TO_THE_BUILD_DIRECTORY
fi

# end of build directory is empty

# check if we need to clean the build directory

# store current working directory
# cd into build directory
# cp -r /usr/share/archiso/configs/profile/* ~/archlive
# add

#echo "[archzfs]\nServer = http://archzfs.com/$repo/x86_64" > archlive/pacman.conf

# mkdir out
# ./build.sh -v

# ask if we should dd this to a sdx device
