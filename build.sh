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

CURRENT_WORKING_DIRECTORY=$(pwd)
#declare -a LIST_OF_AVAILABLE_ZFS_PACKAGES=("archzfs-linux" "archzfs-linux-git" "archzfs-linux-lts")
declare -a LIST_OF_AVAILABLE_ZFS_PACKAGES=("archzfs-linux" "archzfs-linux-git")
LIST_OF_AVAILABLE_ZFS_PACKAGES_AS_STRING=""
PREFIX_FOR_EXECUTING_COMMAND="sudo "
PATH_OF_THIS_FILE=$(cd $(dirname "${BASH_SOURCE[0]}"); pwd)
PATH_TO_THE_DYNAMIC_DATA_DIRECTORY="${PATH_OF_THIS_FILE}/dynamic_data"
PATH_TO_THE_OUTPUT_DIRECTORY="${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}/out"
PATH_TO_THE_PROFILE_DIRECTORY="/usr/share/archiso/configs/releng"
WHO_AM_I=$(whoami)

#end of variables declaration

#begin of check if we are root

if [[ ${WHO_AM_I} = "root" ]];
then
    PREFIX_FOR_EXECUTING_COMMAND=""
fi

#end of check if we are root

#begin of check if archiso is installed

if [[ ! -d ${PATH_TO_THE_PROFILE_DIRECTORY} ]];
then
    echo ":: No archiso package installed."
    echo ":: We are going to install it now..."
    ${PREFIX_FOR_EXECUTING_COMMAND} pacman -Ssyu archiso
fi

#end of check if archiso is installed

#begin of dynamic data directory exists

if [[ -d ${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY} ]];
then
    DIRECTORY_IS_NOT_EMPTY="$(ls -A ${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY})"

    if [[ ${DIRECTORY_IS_NOT_EMPTY} ]];
    then
        echo ":: Previous build data detected."
        echo ":: Cleaning up now..."
        for FILESYSTEM_ITEM_NAME in $(ls ${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}/ | grep -v out);
        do
            ${PREFIX_FOR_EXECUTING_COMMAND} rm -fr ${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}/${FILESYSTEM_ITEM_NAME}
        done
    fi
else
    mkdir -p ${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}
fi

#end of dynamic data directory exists

#begin of creating the output directory

mkdir -p ${PATH_TO_THE_OUTPUT_DIRECTORY}

#end of creating the output directory

#begin of copying needed profile

cp -r ${PATH_TO_THE_PROFILE_DIRECTORY}/* ${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}

#end of copying needed profile

#begin of user interaction
#@todo ask what kind of archzfs the user wants to use:
#   archzfs-linux (default)
#   archzfs-linux-git
#   archzfs-linux-lts
for INDEX_KEY in "${!LIST_OF_AVAILABLE_ZFS_PACKAGES[@]}";
do
    LIST_OF_AVAILABLE_ZFS_PACKAGES_AS_STRING+="   ${INDEX_KEY}) ${LIST_OF_AVAILABLE_ZFS_PACKAGES[${INDEX_KEY}]}"
done;

echo ":: There are ${#LIST_OF_AVAILABLE_ZFS_PACKAGES[@]} archzfs repositories available:"
echo ":: Repositories"
echo "${LIST_OF_AVAILABLE_ZFS_PACKAGES_AS_STRING}"
echo ""
read -p "Enter a selection (default=0): " SELECTED_ARCHZFS_REPOSITORY_INDEX
#end of user interaction

#begin of adding archzfs repository and package

#@todo pretty shitty, we are defining the list above but this switch case needs a lot of maintenance
SELECTED_ARCHZFS_REPOSITORY_NAME=${LIST_OF_AVAILABLE_ZFS_PACKAGES[${SELECTED_ARCHZFS_REPOSITORY_INDEX}]}

echo ":: Building with archzfs repository ${SELECTED_ARCHZFS_REPOSITORY_NAME}"

echo "[archzfs]" >> ${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}/pacman.conf
echo "Server = http://archzfs.com/\$repo/x86_64" >> ${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}/pacman.conf
case ${SELECTED_ARCHZFS_REPOSITORY_NAME} in
    "archzfs-linux-git" )
        echo "archzfs-linux-git" >> ${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}/packages.x86_64
        ;;
    "archzfs-linux-lts" )
#@todo begin of support for lts
#@idea (uname -r | grep lts)?
#@see:
#   https://wiki.archlinux.org/index.php/Pacman -> IgnorePkg
#   https://blog.chendry.org/2015/02/06/automating-arch-linux-installation.html
#        echo "linux-lts" >> ${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}/packages.both
#        echo "linux-lts-headers" >> ${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}/packages.both
        echo "archzfs-linux-lts" >> ${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}/packages.x86_64
        ;;
#@todo end of support for lts
    *)
        echo "archzfs-linux" >> ${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}/packages.x86_64
        ;;
esac

#end of adding archzfs repository and package

#begin of building

cd ${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}

${PREFIX_FOR_EXECUTING_COMMAND} ./build.sh -v

LAST_EXIT_CODE="$?"

if [[ ${LAST_EXIT_CODE} -gt 0 ]];
then
    echo ""
    echo ":: Build failed!"
    echo ":: Cleaning up now..."
    for FILESYSTEM_ITEM_NAME in $(ls ${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}/ | grep -v out);
    do
        ${PREFIX_FOR_EXECUTING_COMMAND} rm -fr ${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}/${FILESYSTEM_ITEM_NAME}
    done
    exit ${LAST_EXIT_CODE}
fi

#end of building

#begin of renaming and hash generation
cd ${PATH_TO_THE_OUTPUT_DIRECTORY}

BUILD_FILE_NAME="archlinux-${SELECTED_ARCHZFS_REPOSITORY_NAME}"
ISO_FILE_NAME="${BUILD_FILE_NAME}.iso"
MD5_FILE_NAME="${ISO_FILE_NAME}.md5sum"
SHA1_FILE_NAME="${ISO_FILE_NAME}.sha1sum"
SHA512_FILE_NAME="${ISO_FILE_NAME}.sha512sum"

if [[ -f ${ISO_FILE_NAME} ]];
then
    echo ":: Older build detected"
    echo ":: Do you want to move the files somewhere? [y|n] (n means overwriting, n is default)"
    read MOVE_EXISTING_BUILD_FILES

    if [[ ${MOVE_EXISTING_BUILD_FILES} == "y" ]];
    then
        echo ":: Please input the path where you want to move the files (if the path does not exist, it will be created):"
        read PATH_TO_MOVE_THE_EXISTING_BUILD_FILES

        if [[ ! -d ${PATH_TO_MOVE_THE_EXISTING_BUILD_FILES} ]];
        then
            echo ":: Creating directory in path: ${PATH_TO_MOVE_THE_EXISTING_BUILD_FILES}"
            ${PREFIX_FOR_EXECUTING_COMMAND} mkdir -p ${PATH_TO_MOVE_THE_EXISTING_BUILD_FILES}
        fi

        echo ":: Moving files ..."
        ${PREFIX_FOR_EXECUTING_COMMAND} mv -v ${BUILD_FILE_NAME}* ${PATH_TO_MOVE_THE_EXISTING_BUILD_FILES}/
    else
        #following lines prevent us from getting asked from mv to override the existing file
        ${PREFIX_FOR_EXECUTING_COMMAND} rm ${ISO_FILE_NAME}
        ${PREFIX_FOR_EXECUTING_COMMAND} rm ${MD5_FILE_NAME}
        ${PREFIX_FOR_EXECUTING_COMMAND} rm ${SHA1_FILE_NAME}
        ${PREFIX_FOR_EXECUTING_COMMAND} rm ${SHA512_FILE_NAME}
    fi
fi

${PREFIX_FOR_EXECUTING_COMMAND} mv archlinux-[0-9]*.iso ${ISO_FILE_NAME}
${PREFIX_FOR_EXECUTING_COMMAND} chown ${WHO_AM_I} ${ISO_FILE_NAME}
${PREFIX_FOR_EXECUTING_COMMAND} sha1sum ${ISO_FILE_NAME} > ${SHA1_FILE_NAME}
${PREFIX_FOR_EXECUTING_COMMAND} md5sum ${ISO_FILE_NAME} > ${MD5_FILE_NAME}
${PREFIX_FOR_EXECUTING_COMMAND} sha512sum ${ISO_FILE_NAME} > ${SHA512_FILE_NAME}
#end of renaming and hash generation

#@todo
#ask if we should dd this to a sdx device

echo ""
echo ":: Iso created in:"
echo " ${PATH_TO_THE_OUTPUT_DIRECTORY}"
echo ":: --------"
echo ":: Listing directory content, filterd by ${SELECTED_ARCHZFS_REPOSITORY_NAME}..."

ls -halt ${PATH_TO_THE_OUTPUT_DIRECTORY} | grep ${SELECTED_ARCHZFS_REPOSITORY_NAME}

cd ${CURRENT_WORKING_DIRECTORY}
