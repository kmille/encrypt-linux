#!/bin/bash
set -euo pipefail

if ! sudo losetup | grep -q $(pwd)/disk-unencrypted.img
then
    sudo kpartx -a disk-unencrypted.img
    LOOP_DEVICE=$(sudo losetup | grep $(pwd)/disk-unencrypted.img | awk '{ print $1 }' | awk -F/ '{ print $3 }')
    sudo losetup
    sudo mount /dev/mapper/"${LOOP_DEVICE}"p1 /mnt
fi

sudo arch-chroot /mnt
