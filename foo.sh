#!/bin/bash

declare -a LIST_OF_AVAILABLE_ZFS_PACKAGES=("archzfs-linux" "archzfs-linux-git" "archzfs-linux-lts")
LIST_OF_AVAILABLE_ZFS_PACKAGES_AS_STRING=""

for INDEX_KEY in "${!LIST_OF_AVAILABLE_ZFS_PACKAGES[@]}";
do
    LIST_OF_AVAILABLE_ZFS_PACKAGES_AS_STRING+="   ${INDEX_KEY}) ${LIST_OF_AVAILABLE_ZFS_PACKAGES[${INDEX_KEY}]}"
done

echo "There are ${#LIST_OF_AVAILABLE_ZFS_PACKAGES[@]} archzfs repositories available"
echo ${LIST_OF_AVAILABLE_ZFS_PACKAGES_AS_STRING}
