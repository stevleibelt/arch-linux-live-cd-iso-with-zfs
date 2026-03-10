#!/bin/bash
#####
# Tries to find existing zfsbootmenu.EFI file and replace this with another one
# Creates a backup of the existing file
####
# @since: 2023-11-10
# @author: stev leibelt <artodeto@bazzline.net>
####

function _echo_if_be_verbose ()
{
  if [[ ${BE_VERBOSE} -eq 1 ]];
  then
    echo "${@}"
  fi
}

function _exit_if_last_exit_code_is_not_zero ()
{
  local ERROR_MESSAGE
  local LAST_COMMAND
  local LAST_EXIT_CODE

  ERROR_MESSAGE="${2:-'Something went wrong'}"
  # fc:     Process the command history list
  # -n:     Suppress command numbers when listing with -l.
  # -l -1:  List the commands with start of -1 (last)
  LAST_COMMAND=$(fc -n -l -1 | trim)
  LAST_EXIT_CODE="${1:-1}"

  if [[ ${LAST_EXIT_CODE} -ne 0 ]];
  then
    echo ":: Error"
    echo "   Last exit code >>${LAST_EXIT_CODE}<<"
    echo "   Last command >>${LAST_COMMAND}<<"
    echo "   >>${ERROR_MESSAGE}<<."

    exit "${LAST_EXIT_CODE}"
  fi
}

function _main ()
{
  if [[ ${UID} != 0 ]];
  then
    echo ":: Script needs to be executed as root"

    exit 10
  fi

  # ref: https://github.com/archlinux/archinstall?tab=readme-ov-file#running-the-guided-installer-using-git
  python -m archinstall
}

_main "${@}"
