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

####
# @param <string: PATH_TO_THE_ARCHLIVE>
# [@param <string: REPO_INDEX_OR_EMPTY_STRING>]
####
function add_packages_and_repository ()
{
    _echo_if_be_verbose ":: Starting adding packages and repository"

    #bo: variable
    local PATH_TO_THE_ARCHLIVE=${1:-""}
    local REPO_INDEX_OR_EMPTY_STRING=${2:-""}

    local PATH_TO_THE_PACKAGES_FILE="${PATH_TO_THE_ARCHLIVE}/packages.x86_64"
    local PATH_TO_THE_PACMAN_CONF_FILE="${PATH_TO_THE_ARCHLIVE}/pacman.conf"
    #eo: variable

    #bo: argument validation
    _exit_if_string_is_empty "PATH_TO_THE_ARCHLIVE" "${PATH_TO_THE_ARCHLIVE}"
    #eo: argument validation

    #bo: environment check
    if [[ ! -d ${PATH_TO_THE_ARCHLIVE} ]];
    then
        echo "   Invalid path to the archlive provided >>${PATH_TO_THE_ARCHLIVE}<< is not a directory."

        exit 1
    else
        _echo_if_be_verbose "   PATH_TO_THE_ARCHLIVE >>${PATH_TO_THE_ARCHLIVE}<<."
    fi

    _echo_if_be_verbose ":: Adding repository and package >>archzfs-linux<<."
    _echo_if_be_verbose "   Using following path to the archlive >>${PATH_TO_THE_ARCHLIVE}<<."

    if [[ ! -f "${PATH_TO_THE_PACKAGES_FILE}" ]];
    then
        echo "   Required file >>${PATH_TO_THE_PACKAGES_FILE}<< was not found."

        exit 5
    else
        _echo_if_be_verbose "   PATH_TO_THE_PACKAGES_FILE >>${PATH_TO_THE_PACKAGES_FILE}<<."
    fi

    if [[ ! -f "${PATH_TO_THE_PACMAN_CONF_FILE}" ]];
    then
        echo "   Required file >>${PATH_TO_THE_PACMAN_CONF_FILE}<< was not found."

        exit 5
    else
        _echo_if_be_verbose "   PATH_TO_THE_PACMAN_CONF_FILE >>${PATH_TO_THE_PACMAN_CONF_FILE}<<."
    fi
    #eo: environment check

    #bo: repo index
    if [[ "${#REPO_INDEX_OR_EMPTY_STRING}" -gt 0 ]];
    then
        _echo_if_be_verbose "   Adapted repo index to >>${REPO_INDEX_OR_EMPTY_STRING}<< in file >>${PATH_TO_THE_PACMAN_CONF_FILE}<<."

        #@see: https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/pull/6/files
        # archzfs repo often lags behind core a week or so, causing zfs kmod/kernel version mismatch and build failure
        # Adding in last week's core archive repo before the official repo as a workaround
        if [[ ${IS_DRY_RUN} -ne 1 ]];
        then
	    _echo_if_be_verbose "   Adding entry of >>Server = https://archive.archlinux.org/repos/${REPO_INDEX_OR_EMPTY_STRING}/\$repo/os/\$arch<< to:"
            _echo_if_be_verbose "       [core]"
            sed -i -e 's|\[core\]|\[core\]\nServer = https://archive.archlinux.org/repos/'${REPO_INDEX_OR_EMPTY_STRING}'/\$repo/os/\$arch/|g' "${PATH_TO_THE_PACMAN_CONF_FILE}"

            _echo_if_be_verbose "       [extra]"
            sed -i -e 's|\[extra\]|\[extra\]\nServer = https://archive.archlinux.org/repos/'${REPO_INDEX_OR_EMPTY_STRING}'/\$repo/os/\$arch/|g' "${PATH_TO_THE_PACMAN_CONF_FILE}"

            _echo_if_be_verbose "       [community]"
            sed -i -e 's|\[community\]|\[community\]\nServer = https://archive.archlinux.org/repos/'${REPO_INDEX_OR_EMPTY_STRING}'/\$repo/os/\$arch/|g' "${PATH_TO_THE_PACMAN_CONF_FILE}"
        fi

    fi
    #eo: repo index

    if [[ ${IS_DRY_RUN} -ne 1 ]];
    then
        _echo_if_be_verbose "   Adding archzfs repositories to PATH_TO_THE_PACMAN_CONF_FILE >>${PATH_TO_THE_PACMAN_CONF_FILE}<<."

        #bo: adding repository
        echo "" >> ${PATH_TO_THE_PACMAN_CONF_FILE}
        echo "[archzfs]" >> ${PATH_TO_THE_PACMAN_CONF_FILE}
        echo "Server = http://archzfs.com/\$repo/\$arch" >> ${PATH_TO_THE_PACMAN_CONF_FILE}
        echo "Server = http://mirror.sum7.eu/archlinux/archzfs/\$repo/\$arch" >> ${PATH_TO_THE_PACMAN_CONF_FILE}
        echo "Server = https://mirror.biocrafting.net/archlinux/archzfs/\$repo/\$arch" >> ${PATH_TO_THE_PACMAN_CONF_FILE}
        #eo: adding repository

        _echo_if_be_verbose "   Adding packages."

        #bo: adding package
        _echo_if_be_verbose "     Addiing package >>git<<."
        echo "git" >> ${PATH_TO_THE_PACKAGES_FILE}

        if [[ ${USE_DKMS} -eq 1 ]];
        then
          #@todo - if we ever want to support lts kernel, we need to adapt this line
          _echo_if_be_verbose "     Addiing package >>linux-headers<<."
          echo "linux-headers" >> ${PATH_TO_THE_PACKAGES_FILE}
          _echo_if_be_verbose "     Addiing package >>zfs-dkms<<."
          echo "zfs-dkms" >> ${PATH_TO_THE_PACKAGES_FILE}
        else
          _echo_if_be_verbose "     Addiing package >>zfs-linux<<."
          echo "zfs-linux" >> ${PATH_TO_THE_PACKAGES_FILE}
          _echo_if_be_verbose "     Addiing package >>zfs-utils<<."
          echo "zfs-utils" >> ${PATH_TO_THE_PACKAGES_FILE}
        fi
        #eo: adding package
        echo ":: Finished adding packages and repository"
    fi
}

####
# @param <string: PATH_TO_THE_WORK_DIRECTORY>
# @param <string: PATH_TO_THE_OUTPUT_DIRECTORY>
# @param <string: PATH_TO_THE_PROFILE_DIRECTORY>
# @param <string: ISO_FILE_PATH>
# @param <string: SHA512_FILE_PATH>
####
function build_archiso ()
{
    _echo_if_be_verbose ":: Starting bulding archiso"

    #bo: variable
    local ISO_FILE_PATH=${4:-""}
    local PATH_TO_THE_PROFILE_DIRECTORY=${3:-""}
    local PATH_TO_THE_OUTPUT_DIRECTORY=${2:-""}
    local PATH_TO_THE_WORK_DIRECTORY=${1:-""}
    local SHA512_FILE_PATH=${5:-""}
    #eo: variable

    #bo: argument validation
    _exit_if_string_is_empty "PATH_TO_THE_WORK_DIRECTORY" "${PATH_TO_THE_WORK_DIRECTORY}"
    _exit_if_string_is_empty "PATH_TO_THE_WORK_DIRECTORY" "${PATH_TO_THE_WORK_DIRECTORY}"
    _exit_if_string_is_empty "PATH_TO_THE_WORK_DIRECTORY" "${PATH_TO_THE_WORK_DIRECTORY}"
    _exit_if_string_is_empty "PATH_TO_THE_PROFILE_DIRECTORY" "${PATH_TO_THE_WORK_DIRECTORY}"
    _exit_if_string_is_empty "ISO_FILE_PATH" "${ISO_FILE_PATH}"
    _exit_if_string_is_empty "SHA512_FILE_PATH" "${SHA512_FILE_PATH}"
    #eo: argument validation

    #bo: environment setup
    if [[ ! -d ${PATH_TO_THE_OUTPUT_DIRECTORY} ]];
    then
        _echo_if_be_verbose "   PATH_TO_THE_OUTPUT_DIRECTORY >>${PATH_TO_THE_OUTPUT_DIRECTORY}<< does not exist."

        _create_directory_or_exit "${PATH_TO_THE_OUTPUT_DIRECTORY}"
    else
        _echo_if_be_verbose "   PATH_TO_THE_OUTPUT_DIRECTORY >>${PATH_TO_THE_OUTPUT_DIRECTORY}<< does exist."
    fi

    if [[ -d "${PATH_TO_THE_WORK_DIRECTORY}" ]];
    then
        _echo_if_be_verbose "   PATH_TO_THE_WORK_DIRECTORY >>${PATH_TO_THE_WORK_DIRECTORY}<< does exist."

        _remove_path_or_exit "${PATH_TO_THE_WORK_DIRECTORY}"
    fi

    _create_directory_or_exit "${PATH_TO_THE_WORK_DIRECTORY}"
    #bo: environment setup

    #begin of building
    if [[ ${IS_DRY_RUN} -ne 1 ]];
    then
        mkarchiso -v -w ${PATH_TO_THE_WORK_DIRECTORY} -o ${PATH_TO_THE_OUTPUT_DIRECTORY} ${PATH_TO_THE_PROFILE_DIRECTORY}
    fi

    LAST_EXIT_CODE="${?}"

    if [[ ${LAST_EXIT_CODE} -gt 0 ]];
    then
        echo ""
        echo "   Build failed!"
        echo "   Exit code of mkarchios >>${LAST_EXIT_CODE}<<."

        exit ${LAST_EXIT_CODE}
    fi
    #end of building

    #begin of renaming and hash generation
    cd ${PATH_TO_THE_OUTPUT_DIRECTORY}

    local NUMBER_OF_ISO_FILES_AVAILABLE=$(find -iname "*.iso" -type f | wc -l)

    if [[ ${IS_DRY_RUN} -ne 1 ]];
    then
        if [[ ${NUMBER_OF_ISO_FILES_AVAILABLE} -gt 0 ]];
        then
            chmod -R 765 *

            _echo_if_be_verbose " Moving >>archlinux-*.iso<< to >>${ISO_FILE_PATH}<<."

            mv archlinux-*.iso ${ISO_FILE_PATH}
            sha512sum ${ISO_FILE_PATH} > ${SHA512_FILE_PATH}
            #end of renaming and hash generation

            _echo_if_be_verbose ""
            _echo_if_be_verbose "   Iso created in path:"
            _echo_if_be_verbose "   PATH_TO_THE_OUTPUT_DIRECTORY >>${PATH_TO_THE_OUTPUT_DIRECTORY}<<"

            _echo_if_be_verbose "   --------"
            echo "   Listing directory content, filterd by >>archzfs<<..."
            ls -halt ${PATH_TO_THE_OUTPUT_DIRECTORY} | grep archzfs

            _echo_if_be_verbose "   --------"
            _echo_if_be_verbose ":: Finished bulding archiso"
        else
            echo ":: No iso file found. Something went wrong."
            echo "   Current path >>${PATH_TO_THE_OUTPUT_DIRECTORY}<<."
            echo "   Number of found >>\*.iso<< files >>${NUMBER_OF_ISO_FILES_AVAILABLE}<<."

            exit 3
        fi
    fi
}

####
# @param <string: ISO_FILE_PATH>
# @param <string: SHA512_FILE_PATH>
####
function cleanup_build_path ()
{
    _echo_if_be_verbose ":: Starting cleanup build path"

    local ISO_FILE_PATH=${1:-""}
    local SHA512_FILE_PATH=${2:-""}

    #bo: argument validation
    _exit_if_string_is_empty "ISO_FILE_PATH" "${ISO_FILE_PATH}"
    _exit_if_string_is_empty "SHA512_FILE_PATH" "${SHA512_FILE_PATH}"
    #eo: argument validation

    #begin of cleanup
    if [[ -f ${ISO_FILE_PATH} ]];
    then
        if [[ ${IS_FORCED} -eq 1 ]];
        then
            _echo_if_be_verbose "   Build is forced, existing build files will be removed automatically."

            MOVE_EXISTING_BUILD_FILES="n"
        else
            echo ":: Older build detected"
            echo ":: Do you want to move the files somewhere? [y|N] (n means overwriting, n is default)"

            read MOVE_EXISTING_BUILD_FILES
        fi

        if [[ ${MOVE_EXISTING_BUILD_FILES} == "y" ]];
        then
            echo ":: Please input the path where you want to move the files (if the path does not exist, it will be created):"

            read PATH_TO_MOVE_THE_EXISTING_BUILD_FILES

            if [[ ! -d ${PATH_TO_MOVE_THE_EXISTING_BUILD_FILES} ]];
            then
                _create_directory_or_exit "${PATH_TO_MOVE_THE_EXISTING_BUILD_FILES}"
            else
                _echo_if_be_verbose "   PATH_TO_MOVE_THE_EXISTING_BUILD_FILES >>${PATH_TO_MOVE_THE_EXISTING_BUILD_FILES}<< exists."
            fi

            _echo_if_be_verbose ":: Moving files ..."

            _echo_if_be_verbose "   Moving >>${ISO_FILE_PATH}<< to >>${PATH_TO_MOVE_THE_EXISTING_BUILD_FILES}<<."

            if [[ ${IS_DRY_RUN} -ne 1 ]];
            then
                mv -v ${ISO_FILE_PATH} ${PATH_TO_MOVE_THE_EXISTING_BUILD_FILES}
            fi

            if [[ -f ${SHA512_FILE_PATH} ]];
            then
                _echo_if_be_verbose "   Moving >>${SHA512_FILE_PATH}<< to >>${PATH_TO_MOVE_THE_EXISTING_BUILD_FILES}<<."

                if [[ ${IS_DRY_RUN} -ne 1 ]];
                then
                    mv -v ${SHA512_FILE_PATH} ${PATH_TO_MOVE_THE_EXISTING_BUILD_FILES}
                fi
            else
                _echo_if_be_verbose "   Moving skipped, >>${SHA512_FILE_PATH}<< does exist."
            fi
        else
            _remove_path_or_exit "${ISO_FILE_PATH}"

            #following lines prevent us from getting asked from mv to override the existing file
            if [[ -f ${SHA512_FILE_PATH} ]];
            then
                _remove_path_or_exit "${SHA512_FILE_PATH}"
            fi
        fi
    else
        _echo_if_be_verbose "   >>${ISO_FILE_PATH}<< does not exist."

        #it can happen that the iso file does not exist but the sha512 file exists
        if [[ -f ${SHA512_FILE_PATH} ]];
        then
            _remove_path_or_exit "${SHA512_FILE_PATH}"
        fi
    fi
    #end of cleanup

    _echo_if_be_verbose ":: Finished cleanup build path"
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

####
# @param <string: PATH_TO_THE_SOURCE_DATA_DIRECTORY>
# @param <string: PATH_TO_THE_PROFILE_DIRECTORY>
####
function evaluate_environment ()
{
    _echo_if_be_verbose ":: Starting evaluating environment"

    local PATH_TO_THE_PROFILE_DIRECTORY=${2:-""}
    local PATH_TO_THE_SOURCE_DATA_DIRECTORY=${1:-""}

    #bo: argument validation
    _exit_if_string_is_empty "PATH_TO_THE_PROFILE_DIRECTORY" "${PATH_TO_THE_PROFILE_DIRECTORY}"
    _exit_if_string_is_empty "PATH_TO_THE_SOURCE_DATA_DIRECTORY" "${PATH_TO_THE_SOURCE_DATA_DIRECTORY}"
    #bo: argument validation

    if [[ ! -d ${PATH_TO_THE_PROFILE_DIRECTORY} ]];
    then
        echo "   Invalid path provided. >>${PATH_TO_THE_PROFILE_DIRECTORY}<< is not a directory."

        exit 1
    else
        _echo_if_be_verbose "   PATH_TO_THE_PROFILE_DIRECTORY >>${PATH_TO_THE_PROFILE_DIRECTORY}<< exists."
    fi

    if [[ ! -d ${PATH_TO_THE_SOURCE_DATA_DIRECTORY} ]];
    then
        echo "   Invalid path provided. >>${PATH_TO_THE_SOURCE_DATA_DIRECTORY}<< is not a directory."

        exit 2
    else
        _echo_if_be_verbose "   PATH_TO_THE_SOURCE_DATA_DIRECTORY >>${PATH_TO_THE_SOURCE_DATA_DIRECTORY}<< exists."
    fi

    #begin of check if pacman-init.service file is still the same
    local FILE_PATH_TO_KEEP_THE_DIFF=$(mktemp)
    local FILE_PATH_TO_THE_SOURCE_PACMAN_INIT_SERVICE="/usr/share/archiso/configs/releng/airootfs/etc/systemd/system/pacman-init.service"
    local FILE_PATH_TO_OUR_PACMAN_INIT_SERVICE="${PATH_TO_THE_SOURCE_DATA_DIRECTORY}/pacman-init.service"
    local FILE_PATH_TO_PACMAN_INIT_SERVICE_EXPECTED_DIFF="${PATH_TO_THE_SOURCE_DATA_DIRECTORY}/pacman-init.service.expected_diff"

    diff ${FILE_PATH_TO_THE_SOURCE_PACMAN_INIT_SERVICE} "${FILE_PATH_TO_OUR_PACMAN_INIT_SERVICE}" > ${FILE_PATH_TO_KEEP_THE_DIFF}

    NUMBER_OF_LINES_BETWEEN_THE_TWO_DIFF_FILES=$(diff ${FILE_PATH_TO_KEEP_THE_DIFF} "${FILE_PATH_TO_PACMAN_INIT_SERVICE_EXPECTED_DIFF}" | wc -l)

    if [[ ${NUMBER_OF_LINES_BETWEEN_THE_TWO_DIFF_FILES} -gt 0 ]];
    then
        echo "   Unexpected runtime environment."
        echo "   The diff between the files >>${FILE_PATH_TO_THE_SOURCE_PACMAN_INIT_SERVICE}<< and >>${FILE_PATH_TO_OUR_PACMAN_INIT_SERVICE}<< results in an unexpected output."
        echo "   Dumping expected diff:"
        echo "${FILE_PATH_TO_PACMAN_INIT_SERVICE_EXPECTED_DIFF}"
        echo ""
        echo "   Dumping current diff:"
        echo "${FILE_PATH_TO_KEEP_THE_DIFF}"
        echo ""
        echo "   Please create an issue in >>https://github.com/stevleibelt/arch-linux-live-cd-iso-with-zfs/issues<<."
        echo ""
        echo "   Will stop now."
        echo ""

        exit 2
    else
        _echo_if_be_verbose "   Updating pacman-init.service"

        if [[ ${IS_DRY_RUN} -ne 1 ]];
        then
            cp "${FILE_PATH_TO_OUR_PACMAN_INIT_SERVICE}" "${PATH_TO_THE_PROFILE_DIRECTORY}/airootfs/etc/systemd/system/pacman-init.service"
        fi
    fi
    #end of check if pacman-init.service file is still the same
    _echo_if_be_verbose ":: Finished evaluating environment"
}

####
# @param <string: "${@}">
####
function auto_elevate_if_not_called_from_root ()
{
    local WHO_AM_I=$(whoami)

    #begin of check if we are root
    if [[ ${WHO_AM_I} != "root" ]];
    then
        #call this script (${0}) again with sudo with all provided arguments (${@})
        _echo_if_be_verbose ":: Current user is not root. Restarting myself."
        _echo_if_be_verbose "   >>sudo \"${0}\" \"${@}\""

	    sudo "${0}" "${@}"

        exit ${?}
    fi
    #end of check if we are root
}

####
# @param <string: PATH_TO_THE_SOURCE_PROFILE_DIRECTORY>
# @param <string: PATH_TO_THE_OUTPUT_DIRECTORY>
####
function setup_environment ()
{
    _echo_if_be_verbose ":: Starting setup environment"

    local PATH_TO_THE_SOURCE_PROFILE_DIRECTORY=${1:-""}
    local PATH_TO_THE_OUTPUT_DIRECTORY=${2:-""}

    #bo: argument validation
    _exit_if_string_is_empty "PATH_TO_THE_SOURCE_PROFILE_DIRECTORY" "${PATH_TO_THE_SOURCE_PROFILE_DIRECTORY}"
    _exit_if_string_is_empty "PATH_TO_THE_OUTPUT_DIRECTORY" "${PATH_TO_THE_OUTPUT_DIRECTORY}"
    #eo: argument validation


    #bo: user input validation
    if [[ ! -d ${PATH_TO_THE_SOURCE_PROFILE_DIRECTORY} ]];
    then
        echo "   Invalid source path for the profile provided >>${PATH_TO_THE_SOURCE_PROFILE_DIRECTORY}<<."
 
        exit 1
    else
        _echo_if_be_verbose "   >>${PATH_TO_THE_SOURCE_PROFILE_DIRECTORY}<< exists."
    fi

    if [[ ! -d ${PATH_TO_THE_OUTPUT_DIRECTORY} ]];
    then
        echo "   Invalid output path provided >>${PATH_TO_THE_OUTPUT_DIRECTORY}<<."

        exit 1
    else
        _echo_if_be_verbose "   >>${PATH_TO_THE_OUTPUT_DIRECTORY}<< exists."
    fi
    #eo: user input validation

    #begin of check if archiso is installed
    if [[ ! -d ${PATH_TO_THE_SOURCE_PROFILE_DIRECTORY} ]];
    then
        _echo_if_be_verbose "   No archiso package installed."
        _echo_if_be_verbose "   Provided path is not a directory >>${PATH_TO_THE_SOURCE_PROFILE_DIRECTORY}<<."
        _echo_if_be_verbose "   We are going to install it now ..."

        if [[ ${IS_DRY_RUN} -ne 1 ]];
        then
            pacman -Syyu archiso
        fi
    else
        _echo_if_be_verbose "   >>${PATH_TO_THE_SOURCE_PROFILE_DIRECTORY}<< exists."
    fi
    #end of check if archiso is installed

    #begin of dynamic data directory exists
    local PROFILE_NAME=$(basename ${PATH_TO_THE_SOURCE_PROFILE_DIRECTORY})
    local PATH_TO_THE_DESTINATION_PROFILE_DIRECTORY="${PATH_TO_THE_OUTPUT_DIRECTORY}/${PROFILE_NAME}"

    if [[ -d ${PATH_TO_THE_DESTINATION_PROFILE_DIRECTORY} ]];
    then
        _echo_if_be_verbose "   Previous profile data detected."
        _echo_if_be_verbose "   >>${PATH_TO_THE_DESTINATION_PROFILE_DIRECTORY}<< exists."
        _echo_if_be_verbose "   Cleaning up now ..."

        _remove_path_or_exit "${PATH_TO_THE_DESTINATION_PROFILE_DIRECTORY}"
    else
        _echo_if_be_verbose "   >>${PATH_TO_THE_DESTINATION_PROFILE_DIRECTORY}<< does not exist, no cleanup needed."
    fi
    #end of dynamic data directory exists

    #begin of creating the output directory
    if [[ ! -p ${PATH_TO_THE_OUTPUT_DIRECTORY} ]];
    then
        _create_directory_or_exit "${PATH_TO_THE_OUTPUT_DIRECTORY}"
    else
        _echo_if_be_verbose "   >>${PATH_TO_THE_OUTPUT_DIRECTORY}<< exists."
    fi
    #end of creating the output directory

    #begin of copying needed profile
    _echo_if_be_verbose "   Copying content off >>${PATH_TO_THE_SOURCE_PROFILE_DIRECTORY}<< to >>${PATH_TO_THE_OUTPUT_DIRECTORY}<<."

    if [[ ${IS_DRY_RUN} -ne 1 ]];
    then
        cp -r ${PATH_TO_THE_SOURCE_PROFILE_DIRECTORY} "${PATH_TO_THE_OUTPUT_DIRECTORY}/"
    fi
    #end of copying needed profile

    _echo_if_be_verbose ":: Finished setup environment"
}

####
# @param <string: path>
####
function _create_directory_or_exit ()
{
    local DIRECTORY_PATH="${1}"

    _echo_if_be_verbose "   Creating directory path >>${DIRECTORY_PATH}<<."

    if [[ ${IS_DRY_RUN} -ne 1 ]];
    then
        /usr/bin/mkdir -p ${DIRECTORY_PATH}
    fi

    local LAST_EXIST_CODE="${?}"

    if [[ ${LAST_EXIT_CODE} -ne 0 ]];
    then
        echo "   Could not create directory path >>${DIRECTORY_PATH}<<. Last exit code >>${LAST_EXIT_CODE}<<.."

        exit ${LAST_EXIT_CODE}
    fi
}

function _remove_path_or_exit ()
{
    local PATH_TO_REMOVE="${1}"

    _echo_if_be_verbose "   Removing path >>${PATH_TO_REMOVE}<<."

    if [[ ${IS_DRY_RUN} -ne 1 ]];
    then
        /usr/bin/rm -fr ${PATH_TO_REMOVE}
    fi

    local LAST_EXIST_CODE="${?}"

    if [[ ${LAST_EXIT_CODE} -ne 0 ]];
    then
        echo "   Could not remove path >>${PATH_TO_REMOVE}<<. Last exit code >>${LAST_EXIT_CODE}<<."

        exit ${LAST_EXIT_CODE}
    fi
}

####
# @param <string: VARIABLE_NAME>
# @param <string: VARIABLE_VALUE>
####
function _exit_if_string_is_empty ()
{
    local VARIABLE_NAME="${1}"
    local VARIABLE_VALUE="${2}"

    if [[ ${#VARIABLE_VALUE} -lt 1 ]];
    then
        echo "   Empty >>${VARIABLE_NAME}<< provided."

        exit 1
    else
        _echo_if_be_verbose "   Valid >>${VARIABLE_NAME}<< provided, value has a string length of >>${#VARIABLE_VALUE}<<."
    fi
}

#####
# @param <string: "${@}">
#####
function _main ()
{
    #@todo:
    #   * add support for dynamic user input
    #       -a|--add-script (add a script like a one we can maintain to easeup setup/installation of "our" archlinux)
    #       -l|--log-output 2>&1 | tee build.log
    #       -p|--package (archzfs-linux or what ever)
    #   * fix not working zfs embedding
    #begin of variables declaration
    local BUILD_FILE_NAME="archlinux-archzfs-linux"
    local CURRENT_WORKING_DIRECTORY=$(pwd)
    local PATH_TO_THIS_SCRIPT=$(cd $(dirname "${BASH_SOURCE[0]}"); pwd)

    local PATH_TO_THE_DYNAMIC_DATA_DIRECTORY="${PATH_TO_THIS_SCRIPT}/dynamic_data"
    local PATH_TO_THE_OPTIONAL_CONFIGURATION_FILE="${PATH_TO_THIS_SCRIPT}/configuration/build.sh"
    local PATH_TO_THE_SOURCE_DATA_DIRECTORY="${PATH_TO_THIS_SCRIPT}/source"

    local PATH_TO_THE_PROFILE_DIRECTORY="${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}/releng"
    local PATH_TO_THE_OUTPUT_DIRECTORY="${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}/out"
    local ISO_FILE_PATH="${PATH_TO_THE_OUTPUT_DIRECTORY}/${BUILD_FILE_NAME}.iso"

    local SHA512_FILE_PATH="${ISO_FILE_PATH}.sha512sum"
    #end of variables declaration

    #bo: user input
    #we are storing all arguments for the case if the script needs to be re-executed as root/system user
    local ALL_ARGUMENTS_TO_PASS="${@}"
    local BE_VERBOSE=0
    local IS_DRY_RUN=0
    local IS_FORCED=0
    local REPO_INDEX="last"
    local SHOW_HELP=0
    local USE_DKMS=0
    local USE_OTHER_REPO_INDEX=0
    local USED_CONFIGURATION_FILE=0

    if [[ -f "${PATH_TO_THE_OPTIONAL_CONFIGURATION_FILE}" ]];
    then
        . "${PATH_TO_THE_OPTIONAL_CONFIGURATION_FILE}"
        local USED_CONFIGURATION_FILE=1
    fi

    while true;
    do
        case "${1}" in
            "-d" | "--dry_run" )
                IS_DRY_RUN=1
                shift 1
                ;;
            "-f" | "--force" )
                IS_FORCED=1
                shift 1
                ;;
            "-h" | "--help" )
                SHOW_HELP=1
                shift 1
                ;;
            "-r" | "--repo-index" )
                USE_OTHER_REPO_INDEX=1
                if [[ ${#2} -gt 0 ]];
                then
                    REPO_INDEX="${2}"
                    shift 2
                else
                    REPO_INDEX="week"
                    shift 1
                fi
                ;;
            "-u" | "--use-dkms" )
                USE_DKMS=1
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

    #bo: code
    if [[ ${SHOW_HELP} -eq 1 ]];
    then
        echo ":: Usage"
        echo "   ${0} [-d|--dry-run] [-f|--force] [-h|--help] [-r|--repo-index [<string: last|week|month|yyyy/mm/dd>]] [-u|--use-dkms] [-v|--verbose]"

        exit 0
    fi

    #we are calling this here to display the help as soon as possible without the need to call sudo
    auto_elevate_if_not_called_from_root "${ALL_ARGUMENTS_TO_PASS}"

    if [[ ${BE_VERBOSE} -eq 1 ]];
    then
        echo ":: Outputting status of the flags."
        echo "   BE_VERBOSE >>${BE_VERBOSE}<<."
        echo "   IS_DRY_RUN >>${IS_DRY_RUN}<<."
        echo "   IS_FORCED >>${IS_FORCED}<<."
        echo "   PATH_TO_THE_OPTIONAL_CONFIGURATION_FILE >>${PATH_TO_THE_OPTIONAL_CONFIGURATION_FILE}<<."
        echo "   REPO_INDEX >>${REPO_INDEX}<<."
        echo "   SHOW_HELP >>${SHOW_HELP}<<."
        echo "   USE_DKMS >>${USE_DKMS}<<."
        echo "   USE_OTHER_REPO_INDEX >>${USE_OTHER_REPO_INDEX}<<."
        echo "   USED_CONFIGURATION_FILE >>${USED_CONFIGURATION_FILE}<<."
        echo ""
    fi

    cd "${PATH_TO_THIS_SCRIPT}"

    cleanup_build_path ${ISO_FILE_PATH} ${SHA512_FILE_PATH}
    setup_environment "/usr/share/archiso/configs/releng" ${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}
    evaluate_environment ${PATH_TO_THE_SOURCE_DATA_DIRECTORY} ${PATH_TO_THE_PROFILE_DIRECTORY}

    if [[ ${USE_OTHER_REPO_INDEX} -eq 0 ]];
    then
        add_packages_and_repository "${PATH_TO_THE_PROFILE_DIRECTORY}"
    else
        add_packages_and_repository "${PATH_TO_THE_PROFILE_DIRECTORY}" "${REPO_INDEX}"
    fi

    build_archiso "${PATH_TO_THE_DYNAMIC_DATA_DIRECTORY}/work" ${PATH_TO_THE_OUTPUT_DIRECTORY} ${PATH_TO_THE_PROFILE_DIRECTORY} ${ISO_FILE_PATH} ${SHA512_FILE_PATH}

    local BUILD_WAS_SUCCESSFUL="${?}"

    if [[ ${BUILD_WAS_SUCCESSFUL} -eq 0 ]];
    then
        if [[ -f "${PATH_TO_THIS_SCRIPT}/run_iso.sh" ]];
        then
            echo ":: Do you want to run the iso for testing? [y|N]"

            read RUN_ISO

            if [[ ${RUN_ISO} == "y" ]];
            then
                bash "${PATH_TO_THIS_SCRIPT}/run_iso.sh" ${ISO_FILE_PATH}
            fi
        else
            echo ":: Expected script is not available in path >>${PATH_TO_THIS_SCRIPT}/run_iso.sh<<."
        fi

        if [[ -f "${PATH_TO_THIS_SCRIPT}/dump_iso.sh" ]];
        then
            echo ":: Do you want to dump the iso on a device? [y|N]"

            read DUMP_ISO

            if [[ ${DUMP_ISO} == "y" ]];
            then
                bash "${PATH_TO_THIS_SCRIPT}/dump_iso.sh" ${ISO_FILE_PATH}
            fi
        else
            echo ":: Expected script is not available in path >>${PATH_TO_THIS_SCRIPT}/dump_iso.sh<<."
        fi

        if [[ -f "${PATH_TO_THIS_SCRIPT}/upload_iso.sh" ]];
        then
            echo ":: Do you want to upload the iso for testing? [y|N]"

            read RUN_ISO

            if [[ ${RUN_ISO} == "y" ]];
            then
                bash "${PATH_TO_THIS_SCRIPT}/upload_iso.sh" ${ISO_FILE_PATH}
            fi
        else
            echo ":: Expected script is not available in path >>${PATH_TO_THIS_SCRIPT}/upload_iso.sh<<."
        fi
    fi

    cd "${CURRENT_WORKING_DIRECTORY}"
    #eo: code
}

####
# @param <string: VARIABLE_NAME>
# @param <string: VARIABLE_VALUE>
####
function _exit_if_string_is_empty ()
{
    local VARIABLE_NAME="${1}"
    local VARIABLE_VALUE="${2}"

    if [[ ${#VARIABLE_VALUE} -lt 1 ]];
    then
        echo "   Empty >>${VARIABLE_NAME}<< provided."

        exit 1
    else
        _echo_if_be_verbose "   Valid >>${VARIABLE_NAME}<< provided, value has a string length of >>${#VARIABLE_VALUE}<<."
    fi
}

_main ${@}
