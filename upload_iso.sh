#!/bin/bash
####
# @author stev leibelt <artodeto@bazzline.net>
# @since 2022-03-19
####

####
# @param <string: arch_iso_file_path>
# @param <string: latest_build_date_file_path>
####
function _create_latest_build_date ()
{
  local ARCH_ISO_FILE_PATH
  local CREATION_DATE_TIME
  local LATEST_BUILD_DATE_FILE_PATH

  ARCH_ISO_FILE_PATH="${1}"
  CREATION_DATE_TIME=""
  LATEST_BUILD_DATE_FILE_PATH="${2}"

  if [[ ! -f "${ARCH_ISO_FILE_PATH}" ]];
  then
    echo ":: Error!"
    echo "   Invalid arch iso file path provided"
    echo "   >>${ARCH_ISO_FILE_PATH}<< is not a file"
    echo ""

    exit 20
  fi

  if [[ -f ${PATH_TO_THE_LATEST_BUILD_DATE} ]];
  then
    if /usr/bin/rm "${PATH_TO_THE_LATEST_BUILD_DATE}";
    then
      _echo_if_be_verbose "   Removed file: ${PATH_TO_THE_LATEST_BUILD_DATE}"
    else
      echo ":: Error - Could not remove file"
      echo "   File path: ${PATH_TO_THE_LATEST_BUILD_DATE}"

      exit 21
    fi
  fi

  _echo_if_be_verbose "   Creating file >>${LATEST_BUILD_DATE_FILE_PATH}<<"

  #add date
  CREATION_DATE_TIME=$(stat -c '%w' "${ARCH_ISO_FILE_PATH}" | cut -d ' ' -f 1)
  _echo_if_be_verbose "       Detected creation date >>${CREATION_DATE_TIME}<<"

  #add time
  CREATION_DATE_TIME=$(echo -n "${CREATION_DATE_TIME}T"; stat -c '%w' "${ARCH_ISO_FILE_PATH}" | cut -d ' ' -f 2 | cut -d '.' -f 1)
  _echo_if_be_verbose "       Detected creation date time >>${CREATION_DATE_TIME}<<"

  touch "${LATEST_BUILD_DATE_FILE_PATH}"

  echo "${CREATION_DATE_TIME}" > "${LATEST_BUILD_DATE_FILE_PATH}"
}

####
# @param <string: output>
####
function _echo_if_be_verbose ()
{
    if [[ ${BE_VERBOSE} -eq 1 ]];
    then
        echo "${1}"
    fi
}

function _main ()
{
    #bo: variables
    local PATH_TO_THE_DISTRIBUTION_ENVIRONMENT_FILE
    local PATH_TO_THE_ISO
    local PATH_TO_THIS_SCRIPT
    local PATH_TO_THE_ISO
    local PATH_TO_THE_ISO_SHA512
    local PATH_TO_THE_LATEST_BUILD_DATE
    local PATH_TO_THE_LOCAL_CONFIGURATION
    local PATH_TO_THE_OPTIONAL_ENVIRONMENT_FILE

    PATH_TO_THIS_SCRIPT=$(cd $(dirname "${BASH_SOURCE[0]}"); pwd)

    PATH_TO_THE_DISTRIBUTION_ENVIRONMENT_FILE="${PATH_TO_THIS_SCRIPT}/.env.dist"
    PATH_TO_THE_OPTIONAL_ENVIRONMENT_FILE="${PATH_TO_THIS_SCRIPT}/.env"
    #eo: variables

    #bo: user input
    #we are storing all arguments for the case if the script needs to be re-executed as root/system user
    local ALL_ARGUMENTS_TO_PASS
    local BE_VERBOSE
    local IS_DRY_RUN
    local KERNEL
    local SHOW_HELP

    ALL_ARGUMENTS_TO_PASS="${@}"
    BE_VERBOSE=0
    IS_DRY_RUN=0
    KERNEL="linux"
    SHOW_HELP=0

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

    while true;
    do
        case "${1}" in
            "-d" | "--dry-run" )
                IS_DRY_RUN=1
                shift 1
                ;;
            "-h" | "--help" )
                SHOW_HELP=1
                shift 1
                ;;
            "-k" | "--kernel" )
                KERNEL="${2:linux}"
                shift 2
                ;;
            "-v" | "--verbose" )
                BE_VERBOSE=1
                shift 1
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
        echo "   ${0} [-d|--dry-run] [-h|--help] [-k|--kernel <string: kernel>] [-v|--verbose]"

        exit 0
    fi
    #bo: help

    PATH_TO_THE_LATEST_BUILD_DATE="${PATH_TO_THIS_SCRIPT}/last_build_date_${KERNEL}.txt"
    PATH_TO_THE_ISO="${PATH_TO_THIS_SCRIPT}/dynamic_data/out/archlinux-archzfs-${KERNEL}.iso"
    PATH_TO_THE_ISO_SHA512="${PATH_TO_THIS_SCRIPT}/dynamic_data/out/archlinux-archzfs-${KERNEL}.iso.sha512sum"

    #bo: output used flags
    if [[ ${BE_VERBOSE} -eq 1 ]];
    then
        echo ":: Outputting status of the flags."
        echo "   BE_VERBOSE >>${BE_VERBOSE}<<."
        echo "   IS_DRY_RUN >>${IS_DRY_RUN}<<."
        echo "   KERNEL >>${KERNEL}<<."
        echo "   SHOW_HELP >>${SHOW_HELP}<<."
        echo ""
    fi
    #eo: output used flags

    #bo: environment check
    if [[ ! -f "${PATH_TO_THE_ISO}" ]];
    then
        echo ":: ERROR - File does not exist!"
        echo "   File path >>${PATH_TO_THE_ISO}<< is invalid."

        exit 1
    fi

    if [[ ! -f "${PATH_TO_THE_ISO_SHA512}" ]];
    then
        _echo_if_be_verbose "   File >>${PATH_TO_THE_ISO_SHA512}<< not found. Creating it."
        sha512sum "${PATH_TO_THE_ISO}" >> "${PATH_TO_THE_ISO_SHA512}"
    fi
    #eo: environment check

    #bo: create latest build date file
    _create_latest_build_date "${PATH_TO_THE_ISO}" "${PATH_TO_THE_LATEST_BUILD_DATE}"
    #eo: create latest build date file

    #bo: upload
    _echo_if_be_verbose "   Starting upload using following arguments:"
    _echo_if_be_verbose "    Files: >>${PATH_TO_THE_LATEST_BUILD_DATE}<<, >>${PATH_TO_THE_ISO_SHA512}<< and >>${PATH_TO_THE_ISO}<<."
    _echo_if_be_verbose "    Key: >>${PATH_TO_SSH_KEY_FILE}<<."
    _echo_if_be_verbose "    Hostpath: >>${SCP_HOST_PATH}<<."

    if [[ ${IS_DRY_RUN} -eq 0 ]];
    then
        if [[ ${BE_VERBOSE} -eq 1 ]];
        then
            scp -v -i "${PATH_TO_SSH_KEY_FILE}" "${PATH_TO_THE_LATEST_BUILD_DATE}" "${PATH_TO_THE_ISO_SHA512}" "${PATH_TO_THE_ISO}" "${SCP_HOST_PATH}"
        else
            scp -i "${PATH_TO_SSH_KEY_FILE}" "${PATH_TO_THE_LATEST_BUILD_DATE}" "${PATH_TO_THE_ISO_SHA512}" "${PATH_TO_THE_ISO}" "${SCP_HOST_PATH}"
        fi
    fi
    #eo: upload
}

_main "${@}"
