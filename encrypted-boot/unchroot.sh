#!/bin/bash
set -x

sudo umount /mnt
sudo cryptsetup luksClose --verbose vm-enc
sudo kpartx -d disk-encrypted-boot.img
sudo losetup
