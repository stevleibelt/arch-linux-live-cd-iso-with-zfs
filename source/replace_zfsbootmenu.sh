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
  LAST_COMMAND="${@:2}"
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

function _usage ()
{
  echo ":: Usage ${0} <options> -i <file>"
  echo " -i <file>        File path to new ZBM.EFI"
  echo ""
  echo "Options"
  echo " -h               Shows this help"
  echo " -o <file>        File path to existing vmlinuz.EFI"
  echo " -v               Enables verbose output"
  echo ""

  exit 0
}

function _main ()
{
  local BE_VERBOSE
  local CURRENT_DATE
  local PATH_TO_NEW_ZBM
  local PATH_TO_OLD_ZBM
  local SHOW_USAGE

  BE_VERBOSE=0
  CURRENT_DATE=$(date +'%Y%m%d')
  PATH_TO_NEW_ZBM=""
  PATH_TO_OLD_ZBM="/efi/EFI/ZBM/vmlinuz.EFI"
  SHOW_USAGE=0

  OPTARG=""
  OPTIND=1

  while getopts "hi:o:v" CURRENT_OPTION;
  do
    case ${CURRENT_OPTION} in
      h)
        SHOW_USAGE=1
        ;;
      i)
        PATH_TO_NEW_ZBM="${OPTARG}"
        ;;
      o)
        PATH_TO_OLD_ZBM="${OPTARG}"
        ;;
      v)
        BE_VERBOSE=1
        ;;
      *)
        echo "${CURRENT_OPTION} is invalid and not supported"
        ;;
    esac
  done

  if [[ ${SHOW_USAGE} -eq 1 ]];
  then
    _usage
  fi

  if [[ ${UID} != 0 ]];
  then
    echo ":: Script needs to be executed as root"

    exit 10
  fi

  if [[ "${PATH_TO_NEW_ZBM}" == "" ]];
  then
    echo ":: No file path to new ZBM.EFI provided"

    exit 20
  fi

  if [[ ! -f "${PATH_TO_NEW_ZBM}" ]];
  then
    echo ":: Invalid input file provided"
    echo "   >>${PATH_TO_NEW_ZBM}<< does not exist"

    exit 25
  fi

  if [[ -f "${PATH_TO_OLD_ZBM}" ]];
  then
    _echo_if_be_verbose "Renaming >>${PATH_TO_OLD_ZBM}<< to >>${PATH_TO_OLD_ZBM}.${CURRENT_DATE}<<"
    mv "${PATH_TO_OLD_ZBM}" "${PATH_TO_OLD_ZBM}.${CURRENT_DATE}"
    _exit_if_last_exit_code_is_not_zero ${?} "Renaming >>{$PATH_TO_OLD_ZBM}<< to >>${PATH_TO_OLD_ZBM}.${CURRENT_DATE}<< failed."
  fi

  _echo_if_be_verbose "Copy >>${PATH_TO_NEW_ZBM}<< to >>${PATH_TO_OLD_ZBM}<<"
  cp "${PATH_TO_NEW_ZBM}" "${PATH_TO_OLD_ZBM}"
  _exit_if_last_exit_code_is_not_zero ${?} "Copy >>${PATH_TO_NEW_ZBM}<< to >>${PATH_TO_OLD_ZBM}<<"
}

_main "${@}"
