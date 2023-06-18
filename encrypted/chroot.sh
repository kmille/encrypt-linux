#!/bin/bash
set -euo pipefail

if ! sudo losetup | grep -q $(pwd)/disk-encrypted.img
then
    sudo kpartx -a disk-encrypted.img
    LOOP_DEVICE=$(sudo losetup | grep $(pwd)/disk-encrypted.img | awk '{ print $1 }' | awk -F/ '{ print $3 }')
    sudo losetup
fi

if ! sudo dmsetup ls | grep -q vm-enc
then
    export PASSWORD=test
    echo $PASSWORD | sudo cryptsetup --verbose luksOpen /dev/mapper/"${LOOP_DEVICE}"p2 vm-enc
fi

if ! mountpoint -q /mnt
then
    sudo mount /dev/mapper/vm-enc /mnt
fi

if ! mountpoint -q /mnt/boot
then
    sudo mount /dev/mapper/"${LOOP_DEVICE}"p1 /mnt/boot
fi

sudo arch-chroot /mnt
