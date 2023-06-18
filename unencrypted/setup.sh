#!/bin/bash
set -eux

CACHE_DIR="/tmp/deb-cache"
mkdir -p $CACHE_DIR

if sudo losetup | grep -q $(pwd)/disk-unencrypted.img
then
    echo "Disk still mounted"
    exit 1
fi

rm -rf disk-unencrypted.img

truncate -s 2GB disk-unencrypted.img
sfdisk disk-unencrypted.img < partitioning.sfdisk

sudo kpartx -a disk-unencrypted.img
sleep 1

LOOP_DEVICE=$(sudo losetup | grep $(pwd)/disk-unencrypted.img | awk '{ print $1 }' | awk -F/ '{ print $3}')
sudo mkfs.ext4 -L root /dev/mapper/"${LOOP_DEVICE}"p1
sudo mount /dev/mapper/"${LOOP_DEVICE}"p1 /mnt

sudo debootstrap --cache-dir="$CACHE_DIR" bookworm /mnt http://deb.debian.org/debian

echo "UUID=$(sudo blkid -s UUID -o value /dev/mapper/${LOOP_DEVICE}p1 )      /               ext4            rw,relatime     0 1" | sudo tee /mnt/etc/fstab

cat <<EOF | sudo arch-chroot /mnt
    echo -e 'LANG="en_US.UTF-8"\nLANGUAGE="en_US:en"\n' > /etc/default/locale
    apt-get -y install locales kbd grub-pc linux-image-amd64

    export PATH=$PATH:/sbin
    echo -n "root:test" | chpasswd

    export LANG="en_US.UTF-8"
    sed -i -e "s/# $LANG/$LANG/" /etc/locale.gen
    locale-gen $LANG
    update-locale LANG=$LANG

    update-initramfs -u
    grub-install /dev/"${LOOP_DEVICE}"
    update-grub
EOF

./unchroot.sh
