rm -rf backup

export LOOP_DEVICE="loop0"

pushd ../unencrypted

./setup.sh
echo "touch ~/created_on_unencrypted_disk" | ./chroot.sh

sudo rm -rf backup && mkdir backup
sudo rsync -av /mnt/ backup

sudo umount /mnt
sudo kpartx -d disk-unencrypted.img 
sudo losetup

sudo dd if=/dev/zero of=disk-unencrypted.img bs=1M

sfdisk disk-unencrypted.img < ../encrypted-boot/partitioning.sfdisk

sudo kpartx -a disk-unencrypted.img
sudo losetup

export PASSWORD=test
echo $PASSWORD | sudo cryptsetup --verbose luksFormat --type luks1 /dev/mapper/"${LOOP_DEVICE}"p1
echo $PASSWORD | sudo cryptsetup --verbose luksOpen /dev/mapper/"${LOOP_DEVICE}"p1 vm-enc

sudo mkfs.ext4 -L root /dev/mapper/vm-enc

sudo mount /dev/mapper/vm-enc /mnt

sudo rsync -av backup/ /mnt

sudo cp /mnt/etc/fstab /mnt/etc/fstab.bak

echo "vm-enc UUID=$(sudo cryptsetup luksUUID /dev/mapper/${LOOP_DEVICE}p1) none luks,discard,initramfs" | sudo tee /mnt/etc/crypttab
sudo chmod 0600 /mnt/etc/crypttab
echo "/dev/mapper/vm-enc      /               ext4            rw,relatime     0 1" | sudo tee /mnt/etc/fstab


cat <<EOF | sudo arch-chroot /mnt
	export PATH=$PATH:/sbin
	apt-get install -y cryptsetup cryptsetup-initramfs
	echo "GRUB_ENABLE_CRYPTODISK=y" >> "/etc/default/grub"
	/sbin/update-initramfs -u
	grub-install /dev/"${LOOP_DEVICE}"
	update-grub
EOF

cat /mnt/root/created_on_unencrypted_disk
sudo rm -rf backup

sudo umount /mnt
sudo cryptsetup luksClose --verbose vm-enc
sudo kpartx -d disk-unencrypted.img
sudo losetup

