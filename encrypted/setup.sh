#!/bin/bash
set -eux

CACHE_DIR="/tmp/deb-cache"
mkdir -p $CACHE_DIR

if sudo losetup | grep -q $(pwd)/disk-encrypted.img
then
    echo "Disk still mounted"
    exit 1
fi

rm -rf disk-encrypted.img

truncate -s 2GB disk-encrypted.img
sfdisk disk-encrypted.img < partitioning.sfdisk

sudo kpartx -a disk-encrypted.img
sleep 1
LOOP_DEVICE=$(sudo losetup | grep $(pwd)/disk-encrypted.img | awk '{ print $1 }' | awk -F/ '{ print $3}')

export PASSWORD=test
echo $PASSWORD | sudo cryptsetup --verbose luksFormat /dev/mapper/"${LOOP_DEVICE}"p2
echo $PASSWORD | sudo cryptsetup --verbose luksOpen /dev/mapper/"${LOOP_DEVICE}"p2 vm-enc

sudo mkfs.ext2 -L boot /dev/mapper/"${LOOP_DEVICE}"p1
sudo mkfs.ext4 -L root /dev/mapper/vm-enc

sudo mount /dev/mapper/vm-enc /mnt
sudo mkdir /mnt/boot
sudo mount /dev/mapper/"${LOOP_DEVICE}"p1 /mnt/boot

sudo debootstrap --cache-dir="$CACHE_DIR" bookworm /mnt http://deb.debian.org/debian

echo "vm-enc UUID=$(sudo cryptsetup luksUUID /dev/mapper/${LOOP_DEVICE}p2) none luks,discard,initramfs" | sudo tee /mnt/etc/crypttab
sudo chmod 0600 /mnt/etc/crypttab
echo "/dev/mapper/vm-enc      /               ext4            rw,relatime     0 1" | sudo tee /mnt/etc/fstab
echo "UUID=$(sudo blkid -s UUID -o value /dev/mapper/${LOOP_DEVICE}p1)  /boot           ext2    defaults        0       2" |  sudo tee -a /mnt/etc/fstab


cat <<EOF | sudo arch-chroot /mnt
    echo -e 'LANG="en_US.UTF-8"\nLANGUAGE="en_US:en"\n' > /etc/default/locale
    apt-get -y install locales kbd grub-pc linux-image-amd64 cryptsetup vim cryptsetup-initramfs

    export PATH=$PATH:/sbin
    echo -n "root:test" | chpasswd

    export LANG="en_US.UTF-8"
    sed -i -e "s/# $LANG/$LANG/" /etc/locale.gen
    locale-gen $LANG
    update-locale LANG=$LANG

    grub-install /dev/"${LOOP_DEVICE}"
    update-grub
EOF

./unchroot.sh
