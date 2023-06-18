#!/bin/bash
set -eu
set -x


if ! sudo losetup | grep -q $(pwd)/disk-encrypted-boot.img
then
    sudo kpartx -a disk-encrypted-boot.img
    sudo losetup
fi

LOOP_DEVICE=$(sudo losetup | grep $(pwd)/disk-encrypted-boot.img | awk '{ print $1 }' | awk -F/ '{ print $3 }')

if ! sudo dmsetup ls | grep -q vm-enc
then
    export PASSWORD=test
    echo $PASSWORD | sudo cryptsetup --verbose luksOpen /dev/mapper/"${LOOP_DEVICE}"p1 vm-enc
fi

if ! mountpoint -q /mnt
then
    sudo mount /dev/mapper/vm-enc /mnt
fi

sudo arch-chroot /mnt
