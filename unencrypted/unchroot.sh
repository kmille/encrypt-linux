#!/bin/bash
set -x

sudo umount /mnt
sudo kpartx -d disk-unencrypted.img
sudo losetup
