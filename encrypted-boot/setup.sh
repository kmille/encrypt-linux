#!/bin/bash
set -eux

CACHE_DIR="/tmp/deb-cache"
mkdir -p $CACHE_DIR

if sudo losetup | grep -q $(pwd)/disk-encrypted-boot.img
then
    echo "Disk still mounted"
    exit 1
fi

rm -rf disk-encrypted-boot.img

truncate -s 2GB disk-encrypted-boot.img
sfdisk disk-encrypted-boot.img < partitioning.sfdisk

sudo kpartx -a disk-encrypted-boot.img
sleep 1
LOOP_DEVICE=$(sudo losetup | grep $(pwd)/disk-encrypted-boot.img | awk '{ print $1 }' | awk -F/ '{ print $3}')

export PASSWORD=test
echo $PASSWORD | sudo cryptsetup --verbose luksFormat --type luks1 /dev/mapper/"${LOOP_DEVICE}"p1
echo $PASSWORD | sudo cryptsetup --verbose luksOpen /dev/mapper/"${LOOP_DEVICE}"p1 vm-enc

sudo mkfs.ext4 -L root /dev/mapper/vm-enc

sudo mount /dev/mapper/vm-enc /mnt

sudo debootstrap --cache-dir="$CACHE_DIR" bookworm /mnt http://deb.debian.org/debian

echo "vm-enc UUID=$(sudo cryptsetup luksUUID /dev/mapper/${LOOP_DEVICE}p1) none luks,discard,initramfs" | sudo tee /mnt/etc/crypttab
echo "/dev/mapper/vm-enc      /               ext4            rw,relatime     0 1" | sudo tee /mnt/etc/fstab

cat <<EOF | sudo arch-chroot /mnt
    echo -e 'LANG="en_US.UTF-8"\nLANGUAGE="en_US:en"\n' > /etc/default/locale
    apt-get -y install locales kbd grub-pc linux-image-amd64 cryptsetup vim cryptsetup-initramfs

    export PATH=$PATH:/sbin
    echo -n "root:test" | chpasswd

    export LANG="en_US.UTF-8"
    sed -i -e "s/# $LANG/$LANG/" /etc/locale.gen
    locale-gen $LANG
    update-locale LANG=$LANG

    echo "GRUB_ENABLE_CRYPTODISK=y" >> "/etc/default/grub"
    update-initramfs -u
    grub-install /dev/"${LOOP_DEVICE}"
    update-grub
EOF

./unchroot.sh
