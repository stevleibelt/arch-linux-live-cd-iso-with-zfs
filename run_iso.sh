#!/bin/bash
####
# @see:
#   https://wiki.archlinux.org/title/Archiso#Test_the_ISO_in_QEMU
#
# @author stev leibelt <artodeto@bazzline.net>
# @since 2022-02-07
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
        if [[ ! -d "/usr/share/qemu" ]];
        then
            echo ":: qemu package is missing, installing it ..."
            pacman -S qemu-full
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
    else
        echo ":: Invalid path provided."
        echo "   >>${PATH_TO_THE_ISO}<< is not a valid file."
    fi
}

_main $@
