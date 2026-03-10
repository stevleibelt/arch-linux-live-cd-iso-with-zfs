#!/bin/bash
####
# Set a efibootmgr entry if needed
####
# @since: 2024-11-17
# @author: stev leibelt <stev.leibelt@hrz.tu-freiberg.de>
####

function _main ()
{
  local DEVICE_LIST

  DEVICE_LIST=$(ls /dev/disk/by-id/*-part*)

  if ! efibootmgr | grep ZFSBootMenu
  then
    echo ":: Adding ZFSBootMenu via efibootmgr"
    echo ":: Select the root device (disk you installed on):"

    select ENTRY in ${DEVICE_LIST};
    do
      DISK="/dev/disk/by-id/${ENTRY}"
      echo "   Using disk: ${DISK}"
      break
    done

    efibootmgr --disk "${DISK}" \
      --part 1 \
      --create \
      --label "ZFSBootMenu" \
      --loader "\EFI\ZBM\vmlinuz.EFI" \
      --verbose
  else
    echo ":: efibootmgr has already a ZFSBootMenu"
  fi
}

_main "${@}"
