#!/bin/bash
####
# @author stev leibelt <artodeto@bazzline.net>
# @since 2022-03-19
####

####
# @param: <string: path_to_the_local_configuration_file
####
function create_local_configuration_file ()
{
    #bo: variables
    local CURRENT_DATE=$(date +'%y-%m-%d')
    local PATH_TO_THE_LOCAL_CONFIGURATION="${1}"

    local PATH_TO_THE_LOCAL_CONFIGURATION_DIST="${PATH_TO_THE_LOCAL_CONFIGURATION}.dist"
    #eo: variables

    #bo: check environment
    if [[ ! -f "${PATH_TO_THE_LOCAL_CONFIGURATION_DIST}" ]];
    then
        echo ":: ERROR - File does not exist!"
        echo "   File path >>${PATH_TO_THE_LOCAL_CONFIGURATION_DIST}<< is invalid."

        exit 1
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

    echo_if_be_verbose "   Created file >>${PATH_TO_THE_LOCAL_CONFIGURATION}<<."
    #eo: user input destination scp host path"
}

####
# @param <string: output>
####
function echo_if_be_verbose ()
{
    if [[ ${BE_VERBOSE} -eq 1 ]];
    then
        echo "${1}"
    fi
}

function _main ()
{
    #bo: variables
    local BE_VERBOSE=0
    local PATH_TO_THE_ISO=${1:-""}
    local PATH_TO_THIS_SCRIPT=$(cd $(dirname "${BASH_SOURCE[0]}"); pwd)

    local PATH_TO_THE_LATEST_BUILD_DATE="${PATH_TO_THIS_SCRIPT}/dynamic_data/out/last_build_date.txt"
    local PATH_TO_THE_ISO="${PATH_TO_THIS_SCRIPT}/dynamic_data/out/archlinux-archzfs-linux.iso"
    local PATH_TO_THE_ISO_SHA512="${PATH_TO_THIS_SCRIPT}/dynamic_data/out/archlinux-archzfs-linux.iso.sha512sum"
    local PATH_TO_THE_LOCAL_CONFIGURATION="${PATH_TO_THIS_SCRIPT}/configuration/upload_iso.sh"
    #eo: variables

    #bo: user input
    #we are storing all arguments for the case if the script needs to be re-executed as root/system user
    local ALL_ARGUMENTS_TO_PASS="${@}"
    local BE_VERBOSE=0
    local IS_DRY_RUN=0
    local SHOW_HELP=0

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
        echo "   ${0} [-d|--dry-run] [-h|--help] [-v|--verbose]"

        exit 0
    fi
    #bo: help

    #bo: output used flags
    if [[ ${BE_VERBOSE} -eq 1 ]];
    then
        echo ":: Outputting status of the flags."
        echo "   BE_VERBOSE >>${BE_VERBOSE}<<."
        echo "   IS_DRY_RUN >>${IS_DRY_RUN}<<."
        echo "   SHOW_HELP >>${SHOW_HELP}<<."
        echo ""
    fi
    #eo: output used flags

    #bo: load or create local configuration
    if [[ ! -f ${PATH_TO_THE_LOCAL_CONFIGURATION} ]];
    then
        echo_if_be_verbose "   No file >>${PATH_TO_THE_LOCAL_CONFIGURATION}<< found."
        create_local_configuration_file "${PATH_TO_THE_LOCAL_CONFIGURATION}"
    fi

    echo_if_be_verbose "   Sourcing file >>${PATH_TO_THE_LOCAL_CONFIGURATION}<< found."
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
        echo_if_be_verbose "   File >>${PATH_TO_THE_ISO_SHA512}<< not found. Creating it."
        sha512sum "${PATH_TO_THE_ISO}" >> "${PATH_TO_THE_ISO_SHA512}"
    fi
    #eo: environment check

    #bo: date creation
    local CREATION_DATE_TIME=""
    #add date
    CREATION_DATE_TIME=$(stat -c '%w' "${PATH_TO_THE_ISO}" | cut -d " " -f1)
    #add time
    CREATION_DATE_TIME=$(echo -n "${CREATION_DATE_TIME}T"; stat -c '%w' "${PATH_TO_THE_ISO}" | cut -d " " -f2 | cut -d "." -f1)

    echo_if_be_verbose "   Creation date time of file >>${PATH_TO_THE_ISO}<< is >>${CREATION_DATE_TIME}<<."

    if [[ -f "${PATH_TO_THE_LATEST_BUILD_DATE}" ]];
    then
      rm "${PATH_TO_THE_LATEST_BUILD_DATE}"
    fi

    touch "${PATH_TO_THE_LATEST_BUILD_DATE}"

    echo "${CREATION_DATE_TIME}" > "${PATH_TO_THE_LATEST_BUILD_DATE}"
    #eo: date creation

    #bo: upload
    echo_if_be_verbose "   Starting upload using following arguments:"
    echo_if_be_verbose "    Files: >>${PATH_TO_THE_LATEST_BUILD_DATE}<<, >>${PATH_TO_THE_ISO_SHA512}<< and >>${PATH_TO_THE_ISO}<<."
    echo_if_be_verbose "    Key: >>${PATH_TO_SSH_KEY_FILE}<<."
    echo_if_be_verbose "    Hostpath: >>${SCP_HOST_PATH}<<."

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
