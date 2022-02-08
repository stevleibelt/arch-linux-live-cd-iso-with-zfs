#!/bin/bash
####
# @see:
#   https://wiki.archlinux.org/title/Archiso#Test_the_ISO_in_QEMU
#
# @author stev leibelt <artodeto@bazzline.net>
# @since 2022-02-07
####

function _main ()
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

_main $#
