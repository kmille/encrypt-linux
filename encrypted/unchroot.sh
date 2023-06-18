#!/bin/bash
set -x

sudo umount /mnt/boot
sudo umount /mnt
sudo cryptsetup luksClose --verbose vm-enc
sudo kpartx -d disk-encrypted.img
sudo losetup
