#!/bin/bash
set -e

echo "=== Setting Timezone and Locale ==="
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "arch-vm" > /etc/hostname

echo "=== Configuring Users ==="
echo "root:root" | chpasswd
useradd -m -G wheel -s /bin/zsh zen0
echo "zen0:password" | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo "=== Adding CachyOS Repositories ==="
# Run the official CachyOS integration script non-interactively
curl -s https://mirror.cachyos.org/cachyos-repo.sh | sh

echo "=== Installing Optimized CachyOS Kernel ==="
pacman -S --noconfirm linux-cachyos linux-cachyos-headers cachyos-settings

echo "=== Configuring Limine Bootloader ==="
mkdir -p /boot/EFI/BOOT
cp /usr/share/limine/BOOTX64.EFI /boot/EFI/BOOT/

ROOT_UUID=$(blkid -s UUID -o value /dev/vda2)

cat << EOF > /boot/limine.conf
timeout: 5

:CachyOS (Optimized)
    protocol: linux
    kernel_path: boot():/vmlinuz-linux-cachyos
    module_path: boot():/initramfs-linux-cachyos.img
    # Here is where you can later inject advanced kernel parameters like 'zswap.enabled=1'
    cmdline: root=UUID=${ROOT_UUID} rw rootflags=subvol=@

:Arch Linux (Standard Kernel Fallback)
    protocol: linux
    kernel_path: boot():/vmlinuz-linux
    module_path: boot():/initramfs-linux.img
    cmdline: root=UUID=${ROOT_UUID} rw rootflags=subvol=@
EOF

echo "=== Configuring Snapper ==="
umount /.snapshots
rm -rf /.snapshots
snapper -c root create-config /
btrfs subvolume delete /.snapshots
mkdir /.snapshots
mount -a

echo "=== Enabling Display Manager ==="
systemctl enable NetworkManager.service
systemctl enable sddm.service

exit
