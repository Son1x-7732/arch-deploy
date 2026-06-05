#!/bin/bash
set -e

echo "=== Wiping and Partitioning /dev/vda ==="
parted -s /dev/vda mklabel gpt mkpart ESP fat32 1MiB 512MiB set 1 esp on mkpart root btrfs 512MiB 100%

echo "=== Formatting Filesystems ==="
mkfs.vfat -F 32 /dev/vda1
mkfs.btrfs -f /dev/vda2

echo "=== Creating Btrfs Subvolumes ==="
mount /dev/vda2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
umount /mnt

echo "=== Mounting Subvolumes ==="
BTRFS_OPTS="noatime,compress=zstd,space_cache=v2"
mount -o subvol=@,$BTRFS_OPTS /dev/vda2 /mnt
mkdir -p /mnt/{boot,home,.snapshots,efi}
mount -o subvol=@home,$BTRFS_OPTS /dev/vda2 /mnt/home
mount -o subvol=@snapshots,$BTRFS_OPTS /dev/vda2 /mnt/.snapshots
mount /dev/vda1 /mnt/efi

echo "=== Pacstrap: Installing Core System ==="
pacstrap -K /mnt base linux linux-firmware btrfs-progs micro git sudo zsh snapper limine

echo "=== Generating Fstab ==="
genfstab -U /mnt >> /mnt/etc/fstab

echo "=== Handing off to Chroot ==="
cp chroot_setup.sh /mnt/
chmod +x /mnt/chroot_setup.sh
arch-chroot /mnt /bin/bash /chroot_setup.sh

echo "=== INSTALLATION COMPLETE! Unmount and Reboot. ==="
rm /mnt/chroot_setup.sh
