#!/usr/bin/env bash
set -euo pipefail

# DISK="vda"
MACHINE_HOSTNAME="laptop"
USERNAME="bryley"

# Void Linux Canberra mirror
REPO="https://mirror.aarnet.edu.au/pub/voidlinux/current"

# Temp safe exit so code doesn't accidently run
exit 1

sfdisk --wipe always --wipe-partitions always /dev/$DISK <<EOF
label: gpt

start=1MiB, size=512MiB, type=U, name=EFI
start=513MiB, type=L, name=ROOT
EOF

mkfs.vfat -F32 -n EFI /dev/disk/by-partlabel/EFI
mkfs.ext4 -F -L ROOT /dev/disk/by-partlabel/ROOT

mount /dev/disk/by-label/ROOT /mnt
mkdir -p /mnt/boot/efi
mount /dev/disk/by-label/EFI /mnt/boot/efi


yes | xbps-install -Syu -R "$REPO" xbps

yes | xbps-install -Sy -R "$REPO" -r /mnt \
    base-system \
    linux \
    linux-firmware \
    grub-x86_64-efi \
    NetworkManager \
    dbus \
    sudo \
    bash \
    nushell \
    neovim


# Resolve DNS
cp /etc/resolv.conf /mnt/etc/resolv.conf

# Fstab
ROOT_UUID="$(blkid -s UUID -o value /dev/disk/by-label/ROOT)"
EFI_UUID="$(blkid -s UUID -o value /dev/disk/by-label/EFI)"

cat > /mnt/etc/fstab <<EOF
UUID=$ROOT_UUID / ext4 defaults,noatime 0 1
UUID=$EFI_UUID /boot/efi vfat defaults,noatime 0 2
EOF


cat > /mnt/root/chroot-setup.sh <<EOF
#!/usr/bin/env bash
set -euo pipefail

echo "$MACHINE_HOSTNAME" > /etc/hostname
ln -sf /usr/share/zoneinfo/Australia/Brisbane /etc/localtime

echo 'en_AU.UTF-8 UTF-8' >> /etc/default/libc-locales
echo 'LANG=en_AU.UTF-8' > /etc/locale.conf

xbps-reconfigure -f glibc-locales

echo 'KEYMAP="us"' >> /etc/rc.conf

ln -s /etc/sv/dbus /etc/runit/runsvdir/default/dbus
ln -s /etc/sv/NetworkManager /etc/runit/runsvdir/default/NetworkManager

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id="Void"
grub-mkconfig -o /boot/grub/grub.cfg

# Enable sudo
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

# Add user
useradd -m -G wheel,audio,video,input,storage,network -s /bin/nu "$USERNAME"

passwd root
passwd "$USERNAME"

xbps-reconfigure -fa
EOF

chmod +x /mnt/root/chroot-setup.sh

xchroot /mnt /root/chroot-setup.sh

# Other small options



# Verify root user

# Verify UEFI

# Verify Void Linux Installer

# Verify Internet access

# Select, partition and format disk

# Mount disk

# Hostname

# Timezone

# User setup (with groups)

# Package installing

