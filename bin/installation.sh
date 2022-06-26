#!/bin/bash
####
# Automated installation of zfs for your arch linux
# I am not the smart guy inventing this. I am just someone glueing things togehter.
####
# @todo
#   Move question into seperate configuration
# @see
#  https://github.com/eoli3n/archiso-zfs
#  https://github.com/eoli3n/arch-config
# @since 20220625T19:25:20
# @author stev leibelt <artodeto@bazzline.net>
####

#bo: configuration
function _run_configuration ()
{
    local DEVICE_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/device"
    local HOSTNAME_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/hostname"
    local LANGUAGE_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/language"
    local LOCAL_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/local"
    local TIMEZONE_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/timezone"
    local USERNAME_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/username"
    local ZPOOLDATASET_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/zpooldataset"
    local ZPOOLNAME_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/zpoolname"

    mkdir "${PATH_TO_THE_CONFIGURATION_DIRECTORY}"

    _ask "Please input your prefered language (default is >>de<<)"
    if [[ ${#REPLY} -ne 2 ]];
    then
        REPLY="de"
    fi
    echo "${REPLY}" > "${LANGUAGE_PATH}"

    _ask "Please insert locales (default is >>de_DE.UTF-8<<)"
    if [[ ${#REPLY} -ne 11 ]];
    then
        REPLY="de_DE.UTF-8"
    fi
    echo "${REPLY}" > "${LOCAL_PATH}"

    _ask "Please input your prefered timezone (default is >>Europe/Berlin<<)"
    if [[ ${#REPLY} -eq 0 ]];
    then
        REPLY="Europe/Berlin"
    fi
    echo "${REPLY}" > "${TIMEZONE_PATH}"

    _ask "Please insert your username: "
    echo "${REPLY}" > "${USERNAME_PATH}"

    #ask user what device he want to use, remove all entries with "-part" to prevent listing partitions
    echo ":: Please select a device where we want to install it."

    select USER_SELECTED_ENTRY in $(ls /dev/disk/by-id/ | grep -v "\-part");
    do
        USER_SELECTED_DEVICE="/dev/disk/by-id/${USER_SELECTED_ENTRY}"
        #store the selection
        echo "${USER_SELECTED_DEVICE}" > "${DEVICE_PATH}"
        break
    done

    _ask "Do you want to add a four character random string to the end of >>zpool<<? (y|N) "

    local ZPOOL_NAME="rpool"
    if echo ${REPLY} | grep -iq '^y$';
    then
        local RANDOM_STRING=$(echo ${RANDOM} | md5sum | head -c 4)

        local ZPOOL_NAME="${ZPOOL_NAME}-${RANDOM_STRING}"
    fi
    echo "${ZPOOL_NAME}" > "${ZPOOLNAME_PATH}"

    _ask "Name of the root dataset below >>${ZPOOL_NAME}/ROOT<< (default is tank)? "
    local ZPOOL_DATASET="${ZPOOL_NAME}/ROOT/${REPLY:-tank}"
    echo "${ZPOOL_DATASET}" > "${ZPOOLDATASET_PATH}"

    _ask "Please insert hostname: "
    echo "${REPLY}" > "${HOSTNAME_PATH}"
}

####
# @param <string: configuration name>
#   device
#   hostname
#   language
#   timezone
#   username
#   zpooldataset
#   zpoolname
####
function _get_from_configuration ()
{
    case ${1} in
        "device")
            CONFIGURATION_FILE_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/device"
            ;;
        "hostname")
            CONFIGURATION_FILE_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/hostname"
            ;;
        "language")
            CONFIGURATION_FILE_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/language"
            ;;
        "local")
            CONFIGURATION_FILE_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/local"
            ;;
        "timezone")
            CONFIGURATION_FILE_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/timezone"
            ;;
        "username")
            CONFIGURATION_FILE_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/username"
            ;;
        "zpooldataset")
            CONFIGURATION_FILE_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/zpooldataset"
            ;;
        "zpoolname")
            CONFIGURATION_FILE_PATH="${PATH_TO_THE_CONFIGURATION_DIRECTORY}/zpoolname"
            ;;
        *)
            CONFIGURATION_FILE_PATH=${RANDOM}
            ;;
    esac

    if [[ -f ${CONFIGURATION_FILE_PATH} ]];
    then
        cat "${CONFIGURATION_FILE_PATH}"
    else
        echo ":: Invalid configuration section >>${1}<< selected."

        ext 1
    fi
}
#eo: configuration

#bo: preparation
function _prepare_environment ()
{
    if grep -q "arch.*iso" /proc/cmdline;
    then
        _echo_if_be_verbose ":: This is an arch.*iso."
    else
        echo ":: Looks like we are not in an >>arch*.iso<< environment."

        exit 1
    fi

    if [[ -d /sys/firmware/efi/efivars ]];
    then
        _echo_if_be_verbose ":: UEFI is available."
    else
        echo ":: Looks like there is no uefi available."
        echo "   Sad thing, uefi is required."

        exit 2
    fi

    if ping archlinux.org -c 1 >/dev/null;
    then
        _echo_if_be_verbose ":: We are online."
    else
        echo ":: Looks like we are offline."
        echo "   Could not ping >>archlinux.org<<."

        exit 3
    fi

    if lsmod | grep -q zfs;
    then
        _echo_if_be_verbose ":: Module zfs is loaded."
    else
        echo ":: Looks like zfs module is not loaded."

        exit 4
    fi

    local LANGUAGE=$(_get_from_configuration "language")
    _echo_if_be_verbose "   Loading keyboad >>${LANGUAGE}<<."
    loadkeys ${LANGUAGE}

    #bo: time
    local TIMEZONE=$(_get_from_configuration "timezone")
    _echo_if_be_verbose "   Setting timezone >>${TIMEZONE}<<."
    timedatectl set-timezone ${REPLY}

    timedatectl set-ntp true
    #eo: time

    _echo_if_be_verbose ":: Increasing cowspace to half of the RAM."

    #usefull to install more
    mount -o remount,size=50% /run/archiso/cowspace
}

function _initialize_archzfs ()
{
    if pacman -Sl archzfs >/dev/null 2>&1;
    then
        _echo_if_be_verbose ":: Archzfs repository already added."

        return
    fi

    _echo_if_be_verbose ":: Adding archzfs to the repository."
    _confirm_every_step

    #adding key
    pacman -Syy archlinux-keyring --noconfirm &>/dev/null
    pacman-key --populate archlinux &>/dev/null
    pacman-key -r DDF7DB817396A49B2A2723F7403BD972F75D9D76
    pacman-key --lsign-key DDF7DB817396A49B2A2723F7403BD972F75D9D76

    #adding repository
    cat >> /etc/pacman.conf <<"DELIM"
[archzfs]
Server = http://archzfs.com/archzfs/x86_64
Server = http://mirror.sum7.eu/archlinux/archzfs/archzfs/x86_64
Server = https://mirror.biocrafting.net/archlinux/archzfs/archzfs/x86_64
DELIM

    #updating packages
    pacman -Sy &>/dev/null

    #@see https://github.com/eoli3n/archiso-zfs/blob/master/init#L46
    #maybe add a flag like >>--archive-version="2022/02/01"<<
}
#eo: preparation

#bo: configuration
function _setup_zfs_passphrase ()
{
    read -r -p "> Please insert your zfs passphrase: " -s USER_INPUT_PASSPHRASE
    echo "" #needed since read does not output \n

    echo "${USER_INPUT_PASSPHRASE}" > /etc/zfs/zroot.key
    chmod 000 /etc/zfs/zroot.key
}

function _wipe_device ()
{
    local DEVICE_PATH=$(_get_from_configuration "device")

    _ask "Do you want to wipe the device >>${DEVICE_PATH}<<? (y|N)"

    if echo ${REPLY} | grep -iq '^y$';
    then
        _echo_if_be_verbose ":: dd >>${DEVICE_PATH}<<.."
        dd if=/dev/zero of="${DEVICE_PATH}" bs=512 count=1

        _echo_if_be_verbose ":: wipefs >>${DEVICE_PATH}<<."
        wipefs -af "${DEVICE_PATH}"

        _echo_if_be_verbose ":: sgdisk >>${DEVICE_PATH}<<."
        sgdisk -Zo "${DEVICE_PATH}"
    else
        echo ":: No wipe, no progress."
        echo "   Will exit now."

        exit 0
    fi
}

function _partition_device ()
{
    local DEVICE_PATH=$(_get_from_configuration "device")

    _echo_if_be_verbose ":: Creating EFI partition."
    sgdisk -n1:1M:+512M -t1:EF00 "${DEVICE_PATH}"
    local EFI_PARTITION="${DEVICE_PATH}-part1"
    
    _echo_if_be_verbose ":: Creating ZFS partition."
    sgdisk -n3:0:0 -t3:bf01 "${DEVICE_PATH}"

    _echo_if_be_verbose ":: Informing kernel about partition changes."
    partprobe "${DEVICE_PATH}"

    _echo_if_be_verbose ":: Formating EFI partition."
    sleep 1 #needed to fix a possible issue that partprobe is not done yet
    mkfs.vfat "${EFI_PARTITION}"
}

function _setup_zpool_and_dataset ()
{
    local DEVICE_PATH=$(_get_from_configuration "device")
    local ZPOOL_NAME=$(_get_from_configuration "zpoolname")
    local ZPOOL_DATASET=$(_get_from_configuration "zpooldataset")

    local EFI_PARTITION="${DEVICE_PATH}-part1"
    local ZFS_PARTITION="${DEVICE_PATH}-part3"

    _echo_if_be_verbose ":: Using device partition >>${ZFS_PARTITION}<<"
    _echo_if_be_verbose "   Creating zfs pool on device path >>${ZFS_PARTITION}<<."

    if [[ ! -h "${EFI_PARTITION}" ]];
    then
        echo ":: Expected device link >>${EFI_PARTITION}<< does not exist."

        exit 1
    fi

    if [[ ! -h "${ZFS_PARTITION}" ]];
    then
        echo ":: Expected device link >>${ZFS_PARTITION}<< does not exist."

        exit 2
    fi

    if [[ ! -f /etc/zfs/zroot.key ]];
    then
        echo ":: Expected file >>/etc/zfs/zroot.key<< does not exist."

        exit 3
    fi

    zpool create -f -o ashift=12                          \
                 -o autotrim=on                           \
                 -O acltype=posixacl                      \
                 -O compression=zstd                      \
                 -O relatime=on                           \
                 -O xattr=sa                              \
                 -O dnodesize=legacy                      \
                 -O encryption=aes-256-gcm                \
                 -O keyformat=passphrase                  \
                 -O keylocation=file:///etc/zfs/zroot.key \
                 -O normalization=formD                   \
                 -O mountpoint=none                       \
                 -O canmount=off                          \
                 -O devices=off                           \
                 -R /mnt                                  \
                 "${ZPOOL_NAME}" "${ZFS_PARTITION}"
    _confirm_every_step

    #bo: create pool
    _echo_if_be_verbose ":: Creating root dataset"
    zfs create -o mountpoint=none "${ZPOOL_NAME}/ROOT"

    _echo_if_be_verbose ":: Set the commandline"
    zfs set org.zfsbootmenu:commandline="ro quiet" "${ZPOOL_NAME}/ROOT"
    #eo: create pool

    #bo: create system dataset
    _echo_if_be_verbose ":: Creating root dataset >>${ZPOOL_DATASET}<<"
    zfs create -o mountpoint=/ -o canmount=noauto "${ZPOOL_DATASET}"

    _echo_if_be_verbose ":: Creating zfs hostid"
    zgenhostid

    _echo_if_be_verbose ":: Configuring bootfs"
    zpool set bootfs="${ZPOOL_DATASET}" "${ZPOOL_NAME}"

    _echo_if_be_verbose ":: Manually mounting dataset"
    zfs mount "${ZPOOL_DATASET}"
    _confirm_every_step
    #eo: create system dataset

    #bo: create home dataset
    _echo_if_be_verbose ":: Creating home dataset"
    zfs create -o mountpoint=/ -o canmount=off "${ZPOOL_NAME}/data"
    zfs create                                 "${ZPOOL_NAME}/data/home"
    _confirm_every_step
    #eo: create home dataset

    #bo: pool reload
    _echo_if_be_verbose ":: Export pool"
    zpool export "${ZPOOL_NAME}"

    _echo_if_be_verbose ":: Import pool"
    zpool import -d /dev/disk/by-id -R /mnt "${ZPOOL_NAME}" -N -f
    zfs load-key "${ZPOOL_NAME}"
    _confirm_every_step
    #eo: pool reload

    #bo: mount system
    _echo_if_be_verbose ":: Mounting system dataset"
    zfs mount "${ZPOOL_DATASET}"
    ##mounting the rest
    zfs mount -a

    _echo_if_be_verbose ":: Mounting EFI partition >>${EFI_PARTITION}<<"
    mkdir -p /mnt/efi
    mount "${EFI_PARTITION}" /mnt/efi
    _confirm_every_step
    #eo: mount system

    #bo: copy zfs cache
    _echo_if_be_verbose ":: Copy zpool cache"
    mkdir -p /mnt/etc/zfs
    zpool set cachefile=/etc/zfs/zpool.cache "${ZPOOL_NAME}"
    _confirm_every_step
    #eo: copy zfs cache
}
#eo: configuration

#bo: general
####
# @param <string: ask message>
####
function _ask ()
{
    read -p ">> ${1}: " -r
    echo
}

function _confirm_every_step ()
{
    if [[ ${CONFIRM_EVERY_STEP} -eq 1 ]];
    then
        read -p "Press enter to continue"
    fi
}

####
# @param <string: message>
####
function _echo_if_be_verbose ()
{
    if [[ ${BE_VERBOSE} -gt 0 ]];
    then
        echo "${1}" 
    fi
}

function _main ()
{
    #bo: variables
    local CURRENT_WORKING_DIRECTORY=$(pwd)
    local CURRENT_DATE_TIME=$(date +""'%Y%m%d-%H%M%S')
    local PATH_TO_THE_CONFIGURATION_DIRECTORY="/tmp/_configuration"
    local PATH_TO_THIS_SCRIPT=$(cd $(dirname "$0"); pwd)
    local CURRENT_RUNNING_KERNEL_VERSION=$(uname -r)
    #eo: variables

    #bo: user input
    local BE_VERBOSE=0
    local CONFIRM_EVERY_STEP=0
    local IS_DRY_RUN=0
    local SHOW_HELP=0

    while true;
    do
        case "${1}" in
            "-c" | "--confirm" )
                CONFIRM_EVERY_STEP=1
                shift 1
                ;;
            "-d" | "--debug" )
                set +x
		        exec &> >(tee "debug.log")
		        echo ":: >>debug.log<< is filled with data"
                IS_DEBUG=1
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

    #bo: verbose output
    if [[ ${BE_VERBOSE} -eq 1 ]];
    then
        echo ":: Dumping variables"
        echo "   CURRENT_WORKING_DIRECTORY: >>${CURRENT_WORKING_DIRECTORY}<<."
        echo "   PATH_TO_THIS_SCRIPT: >>${PATH_TO_THIS_SCRIPT}<<."
        echo "   PROJECT_ROOT_PATH: >>${PROJECT_ROOT_PATH}<<."
        echo "   BE_VERBOSE: >>${BE_VERBOSE}<<."
        echo "   CONFIRM_EVERY_STEP: >>${CONFIRM_EVERY_STEP}<<."
        echo "   CURRENT_RUNNING_KERNEL_VERSION: >>${CURRENT_RUNNING_KERNEL_VERSION}<<."
        echo "   IS_DEBUG: >>${IS_DEBUG}<<."
        echo ""
    fi
    #eo: verbose output

    #bo: help
    if [[ ${SHOW_HELP} -eq 1 ]];
    then
        echo ":: Usage"
        echo "   ${0} [-c|--confirm] [-d|--debug] [-h|--help] [-v|--verbose]"

        exit 0
    fi
    #eo: help

    #bo: configuration
    if [[ ! -d "${PATH_TO_THE_CONFIGURATION_DIRECTORY}" ]];
    then
        _run_configuration
    fi
    #eo: configuration

    #bo: preparation
    _prepare_environment
    _confirm_every_step

    _initialize_archzfs
    _confirm_every_step
    #@see https://github.com/eoli3n/archiso-zfs/blob/master/init#L157
    #I guess we don't need it since we are running an archzfs
    #eo: preparation

    #bo: configuration
    _setup_zfs_passphrase
    _confirm_every_step

    _wipe_device
    _confirm_every_step

    _partition_device
    _confirm_every_step

    _setup_zpool_and_dataset
    _confirm_every_step
    #eo: configuration

    #bo: installation
    _echo_if_be_verbose ":: Sorting mirrors"
    systemctl start reflector

    _echo_if_be_verbose ":: Install base system"
    #@todo: ask for a list or let the user provide a list of tools
    pacstrap /mnt       \
        base            \
        base-devel      \
        linux           \
        linux-headers   \
        linux-firmware  \
        efibootmgr      \
        vim             \
        git             \
        networkmanager
    _confirm_every_step

    local ZPOOL_NAME=$(_get_from_configuration "zpoolname")
    _echo_if_be_verbose ":: Generate fstab excluding zfs entries"
    genfstab -U /mnt | grep -v "${ZPOOL_NAME}" | tr -s '\n' | sed 's/\/mnt//'  > /mnt/etc/fstab

    #bo: hostname
    local USER_HOSTNAME=$(_get_from_configuration "hostname")
    echo "${USER_HOSTNAME}" > /mnt/etc/hostname

    _echo_if_be_verbose ":: Configuring /etc/hosts"
    cat > /mnt/etc/hosts <<DELIM
#<ip-address>	<hostname.domain.org>	<hostname>
127.0.0.1	    localhost   	        ${USER_HOSTNAME}
::1   		    localhost              	${USER_HOSTNAME}
DELIM
    _confirm_every_step
    #eo: hostname

    #bo:
    local USER_INPUT_LANGUAGE=$(_get_from_configuration "language")
    local USER_INPUT_LOCAL=$(_get_from_configuration "local")

    echo "KEYMAP=${USER_INPUT_LANGUAGE}" > /mnt/etc/vconsole.conf
    sed -i "s/#\(${USER_INPUT_LOCAL}\)/\1/" /mnt/etc/locale.gen
    echo "LANG=\"${USER_INPUT_LOCAL}\"" > /mnt/etc/locale.conf

    _echo_if_be_verbose ":: Preparing initramfs"
    cat > /mnt/etc/mkinitcpio.conf <<DELIM
MODULES=()
BINARIES=()
FILES=(/etc/zfs/zroot.key)
HOOKS=(base udev autodetect modconf block keyboard keymap zfs filesystems)
COMPRESSION="zstd"
DELIM
    _confirm_every_step

    _echo_if_be_verbose ":: Copying zfs files"
    cp /etc/hostid /mnt/etc/hostid
    cp /etc/zfs/zpool.cache /mnt/etc/zfs/zpool.cache
    cp /etc/zfs/zroot.key /mnt/etc/zfs
    _confirm_every_step

    local USER_NAME=$(_get_from_configuration "username")

    _echo_if_be_verbose ":: Chroot and configure system"
    arch-chroot /mnt /bin/bash -xe <<DELIM
  ### Reinit keyring
  # As keyring is initialized at boot, and copied to the install dir with pacstrap, and ntp is running
  # Time changed after keyring initialization, it leads to malfunction
  # Keyring needs to be reinitialised properly to be able to sign archzfs key.
  rm -Rf /etc/pacman.d/gnupg
  pacman-key --init
  pacman-key --populate archlinux
  pacman-key -r DDF7DB817396A49B2A2723F7403BD972F75D9D76
  pacman-key --lsign-key DDF7DB817396A49B2A2723F7403BD972F75D9D76
  pacman -S archlinux-keyring --noconfirm
  cat >> /etc/pacman.conf <<"EOSF"
[archzfs]
Server = http://archzfs.com/archzfs/x86_64
Server = http://mirror.sum7.eu/archlinux/archzfs/archzfs/x86_64
Server = https://mirror.biocrafting.net/archlinux/archzfs/archzfs/x86_64
EOSF
  pacman -Syu --noconfirm zfs-utils
  #synchronize clock
  hwclock --systohc

  #set date
  timedatectl set-ntp true
  #@todo: fetch from previous
  timedatectl set-timezone Europe/Berlin

  #generate locale
  locale-gen
  source /etc/locale.conf

  #generate initramfs
  mkinitcpio -P

  #install zfsbootmenu and dependencies
  git clone --depth=1 https://github.com/zbm-dev/zfsbootmenu/ /tmp/zfsbootmenu
  pacman -S cpanminus kexec-tools fzf util-linux --noconfirm
  cd /tmp/zfsbootmenu
  make
  make install
  cpanm --notest --installdeps .

  #create user
  useradd -m ${USER_NAME}
DELIM
    _confirm_every_step

    echo ":: Setting password of >>root<<"
    arch-chroot /mnt /bin/passwd

    echo ":: Setting password of >>${USER_NAME}<<"
    arch-chroot /mnt /bin/passwd "${USER_NAME}"
    _confirm_every_step

    _echo_if_be_verbose ":: Configuring sudo"
    cat > /mnt/etc/sudoers <<DELIM
root ALL=(ALL) ALL
${USER_NAME} ALL=(ALL) ALL
Defaults rootpw
DELIM

    #@todo configure network
    #   https://github.com/eoli3n/arch-config/blob/master/scripts/zfs/install/02-install.sh#L160
    #@todo configure dns
    #   https://github.com/eoli3n/arch-config/blob/master/scripts/zfs/install/02-install.sh#L196

    _echo_if_be_verbose ":: Configuring zfs"
    systemctl enable zfs-import-cache --root=/mnt
    systemctl enable zfs-mount --root=/mnt
    systemctl enable zfs-import.target --root=/mnt
    systemctl enable zfs.target --root=/mnt
    _confirm_every_step

    _echo_if_be_verbose ":: Configure zfs-mount-generator"
    mkdir -p /mnt/etc/zfs/zfs-list.cache
    touch /mnt/etc/zfs/zfs-list.cache/${ZPOOL_NAME}
    zfs list -H -o name,mountpoint,canmount,atime,relatime,devices,exec,readonly,setuid,nbmand | sed 's/\/mnt//' > /mnt/etc/zfs/zfs-list.cache/${ZPOOL_NAME}
    systemctl enable zfs-zed.service --root=/mnt
    _confirm_every_step

    _echo_if_be_verbose ":: Configure zfsbootmenu"
    mkdir -p /mnt/efi/EFI/ZBM

    _echo_if_be_verbose ":: Generate zfsbootmenu efi"
    #@see https://github.com/zbm-dev/zfsbootmenu/blob/master/etc/zfsbootmenu/mkinitcpio.conf
    cat > /mnt/etc/zfsbootmenu/mkinitcpio.conf <<DELIM
MODULES=()
BINARIES=()
FILES=()
HOOKS=(base udev autodetect modconf block keyboard keymap)
COMPRESSION="zstd"
EOF

cat > /mnt/etc/zfsbootmenu/config.yaml <<EOF
Global:
  ManageImages: true
  BootMountPoint: /efi
  InitCPIO: true
Components:
  Enabled: false
EFI:
  ImageDir: /efi/EFI/ZBM
  Versions: false
  Enabled: true
Kernel:
  CommandLine: ro quiet loglevel=0 zbm.import_policy=hostid
  Prefix: vmlinuz
DELIM

    _echo_if_be_verbose ":: Setting commandline"
    zfs set org.zfsbootmenu:commandline="rw quiet nowatchdog rd.vconsole.keymap=${USER_INPUT_LANGUAGE}" "${ZPOOL_DATASET}"
    _confirm_every_step

    local DEVICE_PATH=$(_get_from_configuration "device")

    _echo_if_be_verbose ":: Configuring zfsbootmenu language"
    arch-chroot /mnt /bin/bash -xe <<DELIM
  # Export locale
  export LANG="${USER_INPUT_LOCAL}"
  # Generate zfsbootmenu
  generate-zbm
DELIM

    local DEVICE_PATH=$(_get_from_configuration "device")
    _echo_if_be_verbose ":: Creating UEFI entries"
    
    if ! efibootmgr | grep ZFSBootMenu
    then
        efibootmgr --disk "${DEVICE_PATH}" \
          --part 1 \
          --create \
          --label "ZFSBootMenu Backup" \
          --loader "\EFI\ZBM\vmlinuz-backup.efi" \
          --verbose
        efibootmgr --disk "${DEVICE_PATH}" \
          --part 1 \
          --create \
          --label "ZFSBootMenu" \
          --loader "\EFI\ZBM\vmlinuz.efi" \
          --verbose
    else
        _echo_if_be_verbose "   Boot entries already created"
    fi
    _confirm_every_step

    _echo_if_be_verbose ":: Unmounting all partitions"
    umount /mnt/efi
    zfs umount -a

    _echo_if_be_verbose ":: Exporting zpool"
    zpool export "${ZPOOL_NAME}"
    #eo: installation

    echo ":: Done"
    #cd "${CURRENT_WORKING_DIRECTORY}"
}
#eo: general

_main ${@}
