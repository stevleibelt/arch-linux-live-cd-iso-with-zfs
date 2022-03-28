#!/bin/bash
####
# @author stev leibelt <artodeto@bazzline.net>
# @since 2022-03-28
####

function auto_elevate_if_not_called_from_root ()
{
    #begin of check if we are root
    if [[ ${WHO_AM_I} != "root" ]];
    then
        #call this script (${0}) again with sudo with all provided arguments (${@})
	    sudo "${0}" "${@}"

        exit ${?}
    fi
    #end of check if we are root
}

function _main ()
{
    local PATH_TO_THIS_SCRIPT=$(cd $(dirname "${BASH_SOURCE[0]}"); pwd)
    local PATH_TO_THE_ISO="${1:-${PATH_TO_THIS_SCRIPT}/dynamic_data/out/archlinux-archzfs-linux.iso}"

    auto_elevate_if_not_called_from_root

    if [[ -f "${PATH_TO_THE_ISO}" ]];
    then
        echo ":: Outputting available devices"

        ls /dev/sd* | grep -v '[0-9]$'

        echo ":: Please input the device path you want to dump the iso to."

        read -e PATH_TO_THE_DEVICE

        if [[ -b "${PATH_TO_THE_DEVICE}" ]];
        then
            if [[ -f /usr/bin/progress ]];
            then
                dd if="${PATH_TO_THE_ISO}" of="${PATH_TO_THE_DEVICE}" &
                progress -M
            else
                dd if="${PATH_TO_THE_ISO}" of="${PATH_TO_THE_DEVICE}"
            fi
        else
            echo ":: Devices is invalid."
            echo "   >>${PATH_TO_THE_DEVICE}<< is not a block device."
        fi
    else
        echo ":: Invalid path provided."
        echo "   >>${PATH_TO_THE_ISO}<< is not a valid file."
    fi
}

_main $@
