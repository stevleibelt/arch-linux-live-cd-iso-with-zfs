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
# @param: <string: path_to_the_local_configuration_file
####
function _create_local_configuration_file ()
{
    #bo: variables
    local CURRENT_DATE
    local PATH_TO_THE_LOCAL_CONFIGURATION
    local PATH_TO_THE_LOCAL_CONFIGURATION_DIST

    CURRENT_DATE=$(date +'%y-%m-%d')
    PATH_TO_THE_LOCAL_CONFIGURATION="${1}"

    PATH_TO_THE_LOCAL_CONFIGURATION_DIST="${PATH_TO_THE_LOCAL_CONFIGURATION}.dist"
    #eo: variables

    #bo: check environment
    if [[ ! -f "${PATH_TO_THE_LOCAL_CONFIGURATION_DIST}" ]];
    then
        echo ":: ERROR - File does not exist!"
        echo "   File path >>${PATH_TO_THE_LOCAL_CONFIGURATION_DIST}<< is invalid."

        exit 30
    fi

    echo ":: Local configration file is missing. I will create it but you need to answere some questions."

    cp "${PATH_TO_THE_LOCAL_CONFIGURATION_DIST}" "${PATH_TO_THE_LOCAL_CONFIGURATION}"
    #eo: check environment

    #bo: user input ssh key
    echo "   Please insert the path to the ssh key we want to use."
    #-e: enable readline. @see https://stackoverflow.com/questions/4819819/get-autocompletion-when-invoking-a-read-inside-a-bash-script
    read -e PATH_TO_SSH_KEY_FILE

    #eo: user input ssh key

    #bo: user input destination scp host path"
    echo "   Please insert the destionation host path."
    echo "   Example: foo@bar.net:/foo/bar"
    read SCP_HOST_PATH

    echo "#@since: ${CURRENT_DATE}" >> "${PATH_TO_THE_LOCAL_CONFIGURATION}"
    echo "####" >> "${PATH_TO_THE_LOCAL_CONFIGURATION}"
    echo "" >> "${PATH_TO_THE_LOCAL_CONFIGURATION}"
    echo "#0 = off, 1 = on" >> "${PATH_TO_THE_LOCAL_CONFIGURATION}"
    echo "local PATH_TO_SSH_KEY_FILE=\"${PATH_TO_SSH_KEY_FILE}\"" >> "${PATH_TO_THE_LOCAL_CONFIGURATION}"
    echo "local SCP_HOST_PATH=\"${SCP_HOST_PATH}\"" >> "${PATH_TO_THE_LOCAL_CONFIGURATION}"

    _echo_if_be_verbose "   Created file >>${PATH_TO_THE_LOCAL_CONFIGURATION}<<."
    #eo: user input destination scp host path"
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
    local PATH_TO_THE_ISO
    local PATH_TO_THIS_SCRIPT
    local PATH_TO_THE_ISO
    local PATH_TO_THE_ISO_SHA512
    local PATH_TO_THE_LATEST_BUILD_DATE
    local PATH_TO_THE_LOCAL_CONFIGURATION


    PATH_TO_THIS_SCRIPT=$(cd $(dirname "${BASH_SOURCE[0]}"); pwd)

    PATH_TO_THE_LOCAL_CONFIGURATION="${PATH_TO_THIS_SCRIPT}/configuration/upload_iso.sh"
    #eo: variables

    #bo: user input
    #we are storing all arguments for the case if the script needs to be re-executed as root/system user
    local ALL_ARGUMENTS_TO_PASS
    local BE_VERBOSE
    local IS_DRY_RUN
    local IS_LTS_KERNEL
    local SHOW_HELP

    ALL_ARGUMENTS_TO_PASS="${@}"
    BE_VERBOSE=0
    IS_DRY_RUN=0
    IS_LTS_KERNEL=0
    SHOW_HELP=0

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
            "-l" | "--lts" )
                IS_LTS_KERNEL=1
                shift 1
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
        echo "   ${0} [-d|--dry-run] [-h|--help] [-l|--lts] [-v|--verbose]"

        exit 0
    fi
    #bo: help

    if [[ ${IS_LTS_KERNEL} -eq 1 ]];
    then
      PATH_TO_THE_LATEST_BUILD_DATE="${PATH_TO_THIS_SCRIPT}/last_build_date_lts.txt"
      PATH_TO_THE_ISO="${PATH_TO_THIS_SCRIPT}/dynamic_data/out/archlinux-archzfs-linux-lts.iso"
      PATH_TO_THE_ISO_SHA512="${PATH_TO_THIS_SCRIPT}/dynamic_data/out/archlinux-archzfs-linux-lts.iso.sha512sum"
    else
      PATH_TO_THE_LATEST_BUILD_DATE="${PATH_TO_THIS_SCRIPT}/last_build_date.txt"
      PATH_TO_THE_ISO="${PATH_TO_THIS_SCRIPT}/dynamic_data/out/archlinux-archzfs-linux.iso"
      PATH_TO_THE_ISO_SHA512="${PATH_TO_THIS_SCRIPT}/dynamic_data/out/archlinux-archzfs-linux.iso.sha512sum"
    fi

    #bo: output used flags
    if [[ ${BE_VERBOSE} -eq 1 ]];
    then
        echo ":: Outputting status of the flags."
        echo "   BE_VERBOSE >>${BE_VERBOSE}<<."
        echo "   IS_DRY_RUN >>${IS_DRY_RUN}<<."
        echo "   IS_LTS_KERNEL >>${IS_LTS_KERNEL}<<."
        echo "   SHOW_HELP >>${SHOW_HELP}<<."
        echo ""
    fi
    #eo: output used flags

    #bo: load or create local configuration
    if [[ ! -f ${PATH_TO_THE_LOCAL_CONFIGURATION} ]];
    then
        _echo_if_be_verbose "   No file >>${PATH_TO_THE_LOCAL_CONFIGURATION}<< found."
        _create_local_configuration_file "${PATH_TO_THE_LOCAL_CONFIGURATION}"
    fi

    _echo_if_be_verbose "   Sourcing file >>${PATH_TO_THE_LOCAL_CONFIGURATION}<< found."
    source "${PATH_TO_THE_LOCAL_CONFIGURATION}"
    #eo: load or create local configuration

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

_main ${@}
