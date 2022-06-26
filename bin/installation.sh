#!/bin/bash
####
# Automated installation of zfs for your arch linux
# I am not the smart guy inventing this. I am just someone glueing things togehter.
####
# @see
#  https://github.com/eoli3n/archiso-zfs
#  https://github.com/eoli3n/arch-config
# @since 20220625T19:25:20
# @author stev leibelt <artodeto@bazzline.net>
####

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
    fi
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

    _ask "Please input your prefered language (default is >>de<<): "

    if [[ ${#REPLY} -ne 2 ]];
    then
        REPLY="de"
    fi

    loadkeys ${REPLY}

    #bo: time
    _ask "Please input your prefered timezone (defualt is >>Europe/Berlin<<): "

    if [[ ${#REPLY} -gt 0 ]];
    then
        timedatectl set-timezone ${REPLY}
    fi

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
function _select_device ()
{
    #ask user what device he want to use, remove all entries with "-part" to prevent listing partitions
    echo ":: Please select a device where we want to install it."

    select USER_SELECTED_ENTRY in $(ls /dev/disk/by-id/ | grep -v "\-part");
    do
        USER_SELECTED_DEVICE="/dev/disk/by-id/${USER_SELECTED_ENTRY}"
        #store the selection
        echo "${USER_SELECTED_DEVICE}" > /tmp/_selected_device
        echo ":: We will install on >>${USER_SELECTED_DEVICE}<<."
        break
    done
}

function _setup_zfs_passphrase ()
{
    read -r -p "> Please insert your zfs passphrase: " -s USER_INPUT_PASSPHRASE
    echo "" #needed since read does not output \n

    echo "${USER_INPUT_PASSPHRASE}" > /etc/zfs/zroot.key
    chmod 000 /etc/zfs/zroot.key
}

function _wipe_device ()
{
    local DEVICE=$(cat /tmp/_selected_device)
    _ask "Do you want to wipe the device >>${DEVICE}<<? (y|N) "

    if [[ ${REPLY} =~ ^[Yy]$ ]];
    then
        _echo_if_be_verbose ":: dd >>${DEVICE}<<.."
        dd if=/dev/zeri of="${DEVICE}" bs=512 count=1

        _echo_if_be_verbose ":: wipefs >>${DEVICE}<<."
        wipefs -af "${DEVICE}"

        _echo_if_be_verbose ":: sgdisk >>${DEVICE}<<."
        sgdisk -Zo "${DEVICE}"
    else
        echo ":: No wipe, no progress."
        echo "   Will exit now."

        exit 0
    fi
}

function _partition_device ()
{
    local DEVICE=$(cat /tmp/_selected_device)

    _echo_if_be_verbose ":: Creating EFI partition."
    sgdisk -n1:1M:+512M -t1:EF00 "${DEVICE}"
    local EFI_PARTITION="${DEVICE}-part1"
    
    _echo_if_be_verbose ":: Creating ZFS partition."
    sgdisk -n3:0:0 -t3:bf01 "${DEVICE}"

    _echo_if_be_verbose ":: Informing kernel about partition changes."
    partprobe "${DEVICE}"

    _echo_if_be_verbose ":: Formating EFI partition."
    sleep 1 #needed to fix a possible issue that partprobe is not done yet
    mkfs.vfat "${EFI_PARTITION}"
}

function _setup_zpool_and_dataset ()
{
    local DEVICE=$(cat /tmp/_selected_device)
    local ZPOOL_NAME="zpool"

    local EFI_PARTITION="${DEVICE}-part1"
    local ZFS_PARTITION="${DEVICE}-part3"

    _ask "Do you want to add a four character random string to the end of >>zpool<<? (y|N) "

    if [[ ${REPLY} =~ ^[Yy]$ ]];
    then
        local RANDOM_STRING=$(echo ${RANDOM} | md5sum | head -c 4)

        local ZPOOL_NAME="${ZPOOL_NAME-${RANDOM_STRING}}"
    fi

    _echo_if_be_verbose ":: Using device partition >>${ZFS_PARTITION}<<"
    _echo_if_be_verbose "   Creating zfs pool"

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

    _echo_if_be_verbose ":: Creating root dataset"
    zfs create -o mountpoint=none "${ZPOOL_NAME}/ROOT"

    _echo_if_be_verbose ":: Set the commandline"
    zfs set org.zfsbootmenu:commandline="ro quiet" "${ZPOOL_NAME}/ROOT"

    _ask "Name of the root dataset below >>${ZPOOL_NAME}/ROOT<<? "
    local ZPOOL_ROOT_DATASET="${ZPOOL_NAME}/ROOT/${REPLY}"

    _echo_if_be_verbose ":: Creating root dataset"
    zfs create -o mountpoint=/ -o canmount=noauto "${ZPOOL_ROOT_DATASET}"

    _echo_if_be_verbose ":: Creating zfs hostid"
    zgenhostid

    _echo_if_be_verbose ":: Configuring bootfs"
    zpool set bootfs="${ZPOOL_ROOT_DATASET}" "${ZPOOL_NAME}"

    _echo_if_be_verbose ":: Manually mounting dataset"
    zfs mount "${ZPOOL_ROOT_DATASET}"

    _echo_if_be_verbose ":: Creating home dataset"
    zfs -create -o mountpoint=/ -o canmount=off "${ZPOOL_NAME}/data"
    zfs -create                                 "${ZPOOL_NAME}/data/home"

    _echo_if_be_verbose ":: Export pool"
    zpool export "${ZPOOL_NAME}"

    _echo_if_be_verbose ":: Import pool"
    zpool import -d /dev/disk/by-id -R /mnt "${ZPOOL_NAME}" -N -f
    zfs load-key "${ZPOOL_NAME}"

    _echo_if_be_verbose ":: Mounting root dataset"
    zfs mount "${ZPOOL_ROOT_DATASET}"
    zfs mount -a

    _echo_if_be_verbose ":: Mounting EFI partition"
    mkdir -p /mnt/efi
    mount "${EFI_PARTITION}" /mnt/efi

    _echo_if_be_verbose ":: Copy zpool cache"
    mkdir -p /mnt/etc/zfs
    zpool set cachefile=/etc/zfs/zpool.cache "${ZPOOL_NAME}"
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
    local PATH_TO_THIS_SCRIPT=$(cd $(dirname "$0"); pwd)
    local CURRENT_RUNNING_KERNEL_VERSION=$(uname -r)
    #eo: variables

    #bo: user input
    local BE_VERBOSE=0
    local IS_DRY_RUN=0
    local SHOW_HELP=0

    while true;
    do
        case "${1}" in
            "-d" | "--debug" )
                set +x
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
        echo "   IS_DEBUG: >>${IS_DEBUG}<<."
        echo "   CURRENT_RUNNING_KERNEL_VERSION: >>${CURRENT_RUNNING_KERNEL_VERSION}<<."
        echo ""
    fi
    #eo: verbose output

    #bo: help
    if [[ ${SHOW_HELP} -eq 1 ]];
    then
        echo ":: Usage"
        echo "   ${0} [-d|--debug] [-h|--help] [-v|--verbose]"

        exit 0
    fi
    #eo: help

    #bo: preparation
    _prepare_environment
    _initialize_archzfs
    #@see https://github.com/eoli3n/archiso-zfs/blob/master/init#L157
    #I guess we don't need it since we are running an archzfs
    #eo: preparation

    #bo: configuration
    _select_device
    _setup_zfs_passphrase
    _wipe_device
    _partition_device
    _setup_zpool_and_dataset
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

    _echo_if_be_verbose ":: Generate fstab excluding zfs entries"
    genfstab -U /mnt | grep -v "${ZPOOL_NAME}" | tr -s '\n' | sed 's/\/mnt//'  > /mnt/etc/fstab

    _ask "Please insert hostname: "
    echo "${REPLY}" > /mnt/etc/hostname

    _echo_if_be_verbose ":: Configuring /etc/hosts"
    cat > /mnt/etc/hosts <<DELIM
#<ip-address>	<hostname.domain.org>	<hostname>
127.0.0.1	    localhost   	        ${REPLY}
::1   		    localhost              	${REPLY}
DELIM

    _ask "Please insert locales (de_DE.UTF-8): "
    if [[ ${#REPLY} -ne 11 ]];
    then
        REPLY="de_DE.UTF-8"
    fi

    #${REPLY:0:2}=de
    local USER_INPUT_LANGUAGE="${REPLY:0:2}"
    local USER_INPUT_LOCAL="${REPLY}"

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

    _echo_if_be_verbose ":: Copying zfs files"
    cp /etc/hostid /mnt/etc/hostid
    cp /etc/zfs/zpool.cache /mnt/etc/zfs/zpool.cache
    cp /etc/zfs/zroot.key /mnt/etc/zfs

    _ask "Please insert your username: "
    local USER_NAME=${REPLY}

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

    echo ":: Setting password of >>root<<"
    arch-chroot /mnt /bin/passwd

    echo ":: Setting password of >>${USER_NAME}<<"
    arch-chroot /mnt /bin/passwd "${USER_NAME}"

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

    _echo_if_be_verbose ":: Configure zfs-mount-generator"
    mkdir -p /mnt/etc/zfs/zfs-list.cache
    touch /mnt/etc/zfs/zfs-list.cache/${ZPOOL_NAME}
    zfs list -H -o name,mountpoint,canmount,atime,relatime,devices,exec,readonly,setuid,nbmand | sed 's/\/mnt//' > /mnt/etc/zfs/zfs-list.cache/${ZPOOL_NAME}
    systemctl enable zfs-zed.service --root=/mnt

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
    zfs set org.zfsbootmenu:commandline="rw quiet nowatchdog rd.vconsole.keymap=${USER_INPUT_LANGUAGE}" "${ZPOOL_ROOT_DATASET}"

    _echo_if_be_verbose ":: Configuring zfsbootmenu language"
    arch-chroot /mnt /bin/bash -xe <<DELIM
  # Export locale
  export LANG="${USER_INPUT_LOCAL}"
  # Generate zfsbootmenu
  generate-zbm
DELIM

    _echo_if_be_verbose ":: Creating UEFI entries"
    local USER_SELECTED_DEVICE=$(cat /tmp/_selected_device)
    
    if ! efibootmgr | grep ZFSBootMenu
    then
        efibootmgr --disk "${USER_SELECTED_DEVICE}" \
          --part 1 \
          --create \
          --label "ZFSBootMenu Backup" \
          --loader "\EFI\ZBM\vmlinuz-backup.efi" \
          --verbose
        efibootmgr --disk "${USER_SELECTED_DEVICE}" \
          --part 1 \
          --create \
          --label "ZFSBootMenu" \
          --loader "\EFI\ZBM\vmlinuz.efi" \
          --verbose
    else
        _echo_if_be_verbose "   Boot entries already created"
    fi

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
