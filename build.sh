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

function add_packages_and_repository ()
{
    #begin of adding archzfs repository and package
    # Adding key for the archzfs repository
    #pacman-key -r ${ARCHZFSKEY}
    echo ":: Building with archiso with package >>archzfs-linux<<."

    echo "[archzfs]" >> ${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}/pacman.conf
    echo "Server = http://archzfs.com/\$repo/\$arch" >> ${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}/pacman.conf
    echo "Server = http://mirror.sum7.eu/archlinux/archzfs/\$repo/\$arch" >> ${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}/pacman.conf
    echo "Server = https://mirror.biocrafting.net/archlinux/archzfs/\$repo/\$arch" >> ${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}/pacman.conf

    echo "archzfs-linux" >> ${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}/packages.x86_64
    #end of adding archzfs repository and package
}

function build_archiso ()
{
    #begin of building
    mkarchiso -v -w ${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY} -o ${PATH_TO_THE_OUTPUT_DIRECTORY} ${PATH_TO_THE_PROFILE_DIRECTORY}

    LAST_EXIT_CODE="$?"

    if [[ ${LAST_EXIT_CODE} -gt 0 ]];
    then
        echo ""
        echo ":: Build failed!"
        echo ":: Cleaning up now..."
        for FILESYSTEM_ITEM_NAME in $(ls ${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}/ | grep -v out);
        do
            rm -fr ${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}/${FILESYSTEM_ITEM_NAME}
        done
        exit ${LAST_EXIT_CODE}
    fi
    #end of building

    #begin of renaming and hash generation
    cd ${PATH_TO_THE_OUTPUT_DIRECTORY}

    chmod -R 765 *

    mv archlinux-*.iso ${ISO_FILE_PATH}
    chown ${WHO_AM_I} ${ISO_FILE_PATH}
    sha1sum ${ISO_FILE_PATH} > ${SHA1_FILE_PATH}
    md5sum ${ISO_FILE_PATH} > ${MD5_FILE_PATH}
    sha512sum ${ISO_FILE_PATH} > ${SHA512_FILE_PATH}
    #end of renaming and hash generation

    #@todo
    #ask if we should dd this to a sdx device

    echo ""
    echo ":: Iso created in path:"
    echo "   ${PATH_TO_THE_OUTPUT_DIRECTORY}"
    echo ":: --------"
    echo ":: Listing directory content, filterd by ${SELECTED_ARCHZFS_REPOSITORY_NAME}..."

    ls -halt ${PATH_TO_THE_OUTPUT_DIRECTORY} | grep ${SELECTED_ARCHZFS_REPOSITORY_NAME}
}

function cleanup_build_path ()
{
    #begin of cleanup
    #cd ${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}
    if [[ -f ${ISO_FILE_PATH} ]];
    then
        echo ":: Older build detected"
        echo ":: Do you want to move the files somewhere? [y|N] (n means overwriting, n is default)"
        read MOVE_EXISTING_BUILD_FILES

        if [[ ${MOVE_EXISTING_BUILD_FILES} == "y" ]];
        then
            echo ":: Please input the path where you want to move the files (if the path does not exist, it will be created):"
            read PATH_TO_MOVE_THE_EXISTING_BUILD_FILES

            if [[ ! -d ${PATH_TO_MOVE_THE_EXISTING_BUILD_FILES} ]];
            then
                echo ":: Creating directory in path: ${PATH_TO_MOVE_THE_EXISTING_BUILD_FILES}"
                mkdir -p ${PATH_TO_MOVE_THE_EXISTING_BUILD_FILES}
            fi

            echo ":: Moving files ..."
            mv -v ${BUILD_FILE_NAME}* ${PATH_TO_MOVE_THE_EXISTING_BUILD_FILES}/
        else
            #following lines prevent us from getting asked from mv to override the existing file
            rm ${ISO_FILE_PATH}
            rm ${MD5_FILE_PATH}
            rm ${SHA1_FILE_PATH}
            rm ${SHA512_FILE_PATH}
        fi
    fi
    #end of cleanup
}

function evaluate_environment ()
{
    #begin of check if pacman-init.service file is still the same
    FILE_PATH_TO_KEEP_THE_DIFF=$(mktemp)
    FILE_PATH_TO_THE_SOURCE_PACMAN_INIT_SERVICE="/usr/share/archiso/configs/releng/airootfs/etc/systemd/system/pacman-init.service"
    FILE_PATH_TO_OUR_PACMAN_INIT_SERVICE="${PATH_TO_THE_SOURCE_DATA_DIRECTORY}/pacman-init.service"
    FILE_PATH_TO_PACMAN_INIT_SERVICE_EXPECTED_DIFF="${PATH_TO_THE_SOURCE_DATA_DIRECTORY}/pacman-init.service.expected_diff"

    diff ${FILE_PATH_TO_THE_SOURCE_PACMAN_INIT_SERVICE} "${FILE_PATH_TO_OUR_PACMAN_INIT_SERVICE}" > ${FILE_PATH_TO_KEEP_THE_DIFF}

    NUMBER_OF_LINES_BETWEEN_THE_TWO_DIFF_FILES=$(diff ${FILE_PATH_TO_KEEP_THE_DIFF} "${FILE_PATH_TO_PACMAN_INIT_SERVICE_EXPECTED_DIFF}" | wc -l)

    if [[ ${NUMBER_OF_LINES_BETWEEN_THE_TWO_DIFF_FILES} -gt 0 ]];
    then
        echo ":: Unexpected runtime environment."
        echo "   The diff between the files >>${FILE_PATH_TO_THE_SOURCE_PACMAN_INIT_SERVICE}<< and >>${FILE_PATH_TO_OUR_PACMAN_INIT_SERVICE}<< results in an unexpected output."
        echo "   Dumping expected diff:"
        echo "${FILE_PATH_TO_PACMAN_INIT_SERVICE_EXPECTED_DIFF}"
        echo ""
        echo "   Dumping current diff:"
        echo "${FILE_PATH_TO_KEEP_THE_DIFF}"
        echo ""
        echo ":: Please create an issue in >>https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/issues<<."
        echo ""
        echo ":: Will stop now."
        echo ""

        exit 2
    else
        echo ":: Updating pacman-init.service"

        cp "${FILE_PATH_TO_OUR_PACMAN_INIT_SERVICE}" "${PATH_TO_THE_OUTPUT_DIRECTORY}/airootfs/etc/systemd/system/pacman-init.service"
    fi
    #end of check if pacman-init.service file is still the same
}

function exit_if_not_called_from_root ()
{
    #begin of check if we are root
    if [[ ${WHO_AM_I} != "root" ]];
    then
        echo ":: Script needs to be executed as root."

        exit 1
    fi
    #end of check if we are root
}

function run_iso_if_wanted ()
{
    local PATH_TO_THE_ISO=${1:-""}

    if [[ -f "${PATH_TO_THE_ISO}" ]];
    then
        echo ":: Do you want to run the iso for testing? [y|N]"
        read RUN_ISO

        if [[ ${RUN_ISO} == "y" ]];
        then
            if [[ ! -d "/usr/share/qemu" ]];
            then
                echo ":: qemu package is missing, installing it ..."
                pacman -S qemu
            fi

            if [[ ! -d "/usr/share/edk2-ovmf" ]];
            then
                echo ":: edk2-ovmf package is missing, installing it ..."
                pacman -S edk2-ovmf
            fi

            echo ":: Do you want to run it as UEFI? [y|N]"
            read RUN_AS_UEFI

            if [[ ${RUN_AS_UEFI} == "y" ]];
            then
                run_archiso -u -i ${PATH_TO_THE_ISO}
            else
                run_archiso -i ${PATH_TO_THE_ISO}
            fi
        fi
    else
        echo ":: Invalid path provided."
        echo "   >>${PATH_TO_THE_ISO}<< is not a valid file."
    fi
}

function setup_environment ()
{
    #begin of check if archiso is installed
    if [[ ! -d ${PATH_TO_THE_PROFILE_DIRECTORY} ]];
    then
        echo ":: No archiso package installed."
        echo ":: We are going to install it now..."
        pacman -Syyu archiso
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
                rm -fr ${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}/${FILESYSTEM_ITEM_NAME}
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
    cp -r ${PATH_TO_THE_PROFILE_DIRECTORY}/ ${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}
    #end of copying needed profile
}

function _main ()
{
    #@todo:
    #   * add support for dynamic user input
    #       -f|--force (overwrite existing data)
    #       -l|--log-output
    #       -p|--package (archzfs-linux or what ever)
    #       -v|--verbose (be verbose)
    #   * fix not working zfs embedding
    #begin of variables declaration
    local ARCHZFSKEY="DDF7DB817396A49B2A2723F7403BD972F75D9D76"
    local CURRENT_WORKING_DIRECTORY=$(pwd)
    local LIST_OF_AVAILABLE_ZFS_PACKAGES_AS_STRING=""
    local PATH_OF_THIS_FILE=$(cd $(dirname "${BASH_SOURCE[0]}"); pwd)
    local PATH_TO_THE_DYNAMIC_DATA_DIRECTORY="${PATH_OF_THIS_FILE}/dynamic_data"
    local PATH_TO_THE_OUTPUT_DIRECTORY="${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}/out"
    local PATH_TO_THE_PROFILE_DIRECTORY="/usr/share/archiso/configs/releng"
    local PATH_TO_THE_SOURCE_DATA_DIRECTORY="${PATH_OF_THIS_FILE}/source"
    local WHO_AM_I=$(whoami)

    local BUILD_FILE_NAME="archlinux-archzfs-linux"
    local ISO_FILE_PATH="${PATH_TO_THE_OUTPUT_DIRECTORY}/${BUILD_FILE_NAME}.iso"
    local MD5_FILE_PATH="${ISO_FILE_PATH}.md5sum"
    local SHA1_FILE_PATH="${ISO_FILE_PATH}.sha1sum"
    local SHA512_FILE_PATH="${ISO_FILE_PATH}.sha512sum"
    #end of variables declaration

    exit_if_not_called_from_root
    setup_environment
    evaluate_environment
    add_packages_and_repository
    cleanup_build_path
    build_archiso
    run_iso_if_wanted

    cd ${CURRENT_WORKING_DIRECTORY}
}

_main $#
