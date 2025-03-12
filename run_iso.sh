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
  # bo: variables
  local ISO_BOOT_TYPE
  local KERNEL
  local PATH_TO_THE_DISTRIBUTION_ENVIRONMENT_FILE
  local PATH_TO_THE_ISO
  local PATH_TO_THE_OPTIONAL_ENVIRONMENT_FILE
  local PATH_TO_THIS_SCRIPT
  local WHO_AM_I

  KERNEL="linux"
  PATH_TO_THIS_SCRIPT=$(cd $(dirname "${BASH_SOURCE[0]}"); pwd)
  WHO_AM_I=$(whoami)
  PATH_TO_THE_DISTRIBUTION_ENVIRONMENT_FILE="${PATH_TO_THIS_SCRIPT}/.env.dist"
  PATH_TO_THE_OPTIONAL_ENVIRONMENT_FILE="${PATH_TO_THIS_SCRIPT}/.env"
  # eo: variables

  #bo: load environment files
  set -a
  source "${PATH_TO_THE_DISTRIBUTION_ENVIRONMENT_FILE}"
  set +a
  if [[ -f "${PATH_TO_THE_OPTIONAL_ENVIRONMENT_FILE}" ]];
  then
    set -a
    source "${PATH_TO_THE_OPTIONAL_ENVIRONMENT_FILE}"
    set +a
  fi
  #eo: load environment files

  #bo: user input
  while true;
  do
    case "${1}" in
      "-b" | "--boot-type" )
          ISO_BOOT_TYPE="${2:uefi}"
          shift 2
          ;;
      "-h" | "--help" )
          SHOW_HELP=1
          shift 1
          ;;
      "-k" | "--kernel" )
          KERNEL="${2:linux}"
          shift 2
          ;;
      * )
          break
          ;;
      esac
  done
  #eo: user input

  #bo: help
  if [[ ${SHOW_HELP} -eq 1 ]];
  then
      echo ":: Usage"
      echo "   ${0} [-b|--boot-type <string: boot_type="${ISO_BOOT_TYPE}"] [-k|--kernel <string: kernel=${KERNEL}]"

      exit 0
  fi
  #bo: help

  #bo: environemt check
  PATH_TO_THE_ISO="${PATH_TO_THIS_SCRIPT}/dynamic_data/out/archlinux-archzfs-${KERNEL}.iso"

  if [[ ! -f "${PATH_TO_THE_ISO}" ]];
  then
    echo ":: Invalid path provided."
    echo "   >>${PATH_TO_THE_ISO}<< is not a valid file."

    exit 10
  fi

  if [[ ${WHO_AM_I} == "root" ]];
  then
    local SUDO_COMMAND_PREFIX=""
  else
    local SUDO_COMMAND_PREFIX="sudo "
  fi

  if [[ ! -d "/usr/share/qemu" ]];
  then
    echo ":: qemu package is missing, installing it ..."

    ${SUDO_COMMAND_PREFIX} pacman -S qemu-full
  fi

  if [[ ! -d "/usr/share/edk2-ovmf" ]];
  then
    echo ":: edk2-ovmf package is missing, installing it ..."

    ${SUDO_COMMAND_PREFIX} pacman -S edk2-ovmf
  fi
  #eo: environemt check

  #bo: core logic
  if [[ ${ISO_BOOT_TYPE} == "uefi" ]];
  then
    run_archiso -u -i "${PATH_TO_THE_ISO}"
  else
    run_archiso -b -i "${PATH_TO_THE_ISO}"
  fi
  #eo: core logic
}

_main "${@}"
