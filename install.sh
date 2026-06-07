#!/usr/bin/env bash
set -euo pipefail

# Void Linux Canberra mirror
REPO="https://mirror.aarnet.edu.au/pub/voidlinux/current"

##########
# Checks #
##########

[ "$EUID" -eq 0 ] || { echo "root access required"; exit 1; }
[ -d /sys/firmware/efi ] || { echo "UEFI required"; exit 1; }
command -v xbps-install > /dev/null || { echo "Needs to run inside Void Installer"; exit 1; }
ping -c 1 1.1.1.1 > /dev/null || { echo "internet required"; exit 1; }

##############
# User input #
##############

read -rp "What should the machine name be? " MACHINE_HOSTNAME
read -rp "What is your primary username? " USERNAME

lsblk
read -rp "What disk would you like to wipe/use? eg. nvme0n1: " DISK
[ -n "$DISK" ] || { echo "DISK empty"; exit 1; }
[ -b "/dev/$DISK" ] || { echo "/dev/$DISK not found"; exit 1; }
read -rp "This will erase /dev/$DISK, are you sure? [yN]: " confirm
[ "$confirm" = "y" ] || exit 1

###############
# Setup disks #
###############

# Remove current mounts for clean state
umount -R /mnt 2>/dev/null || true
swapoff -a 2>/dev/null || true

sfdisk --wipe always --wipe-partitions always /dev/$DISK <<EOF
label: gpt

start=1MiB, size=512MiB, type=U, name=EFI
start=513MiB, type=L, name=ROOT
EOF

udevadm settle

mkfs.vfat -F32 -n EFI /dev/disk/by-partlabel/EFI
mkfs.ext4 -F -L ROOT /dev/disk/by-partlabel/ROOT

udevadm settle

mount /dev/disk/by-label/ROOT /mnt
mkdir -p /mnt/boot/efi
mount /dev/disk/by-label/EFI /mnt/boot/efi

################
# Install Disk #
################

# Update xbps for live installer
printf 'y' | xbps-install -Syu -R "$REPO" xbps

# Install the minimum needed to enter the target system and run packages.sh there.
printf 'y' | xbps-install -Sy -R "$REPO" -r /mnt \
    base-system \
    bash \
    git \
    ca-certificates

# Fstab
ROOT_UUID="$(blkid -s UUID -o value /dev/disk/by-label/ROOT)"
EFI_UUID="$(blkid -s UUID -o value /dev/disk/by-label/EFI)"

cat > /mnt/etc/fstab <<EOF
UUID=$ROOT_UUID / ext4 defaults,noatime 0 1
UUID=$EFI_UUID /boot/efi vfat defaults,noatime 0 2
EOF

# Resolve DNS temporarily
cp /etc/resolv.conf /mnt/etc/resolv.conf

# This function will run as if inside the installed system
chroot_setup() {
    set -euo pipefail

    # Use Australia repo
    mkdir -p /etc/xbps.d
    echo "repository=$REPO" > /etc/xbps.d/00-repository-main.conf

    # Install packages
    git clone https://github.com/Bryley/dots.git /tmp/dots
    /tmp/dots/packages.sh

    echo "$MACHINE_HOSTNAME" > /etc/hostname
    ln -sf /usr/share/zoneinfo/Australia/Brisbane /etc/localtime

    grep -qxF 'en_AU.UTF-8 UTF-8' /etc/default/libc-locales || echo 'en_AU.UTF-8 UTF-8' >> /etc/default/libc-locales
    echo 'LANG=en_AU.UTF-8' > /etc/locale.conf

    # Keep /etc/locale.conf as the single source of truth for login sessions.
    # This matters when the login shell is nushell, which does not source /etc/profile.d/locale.sh.
    sed -i 's|^session[[:space:]]\+required[[:space:]]\+pam_env\.so$|session    required   pam_env.so envfile=/etc/locale.conf|' /etc/pam.d/system-login

    xbps-reconfigure -f glibc-locales

    echo 'KEYMAP="us"' >> /etc/rc.conf

    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id="Void" --removable
    grub-mkconfig -o /boot/grub/grub.cfg

    # Enable sudo
    echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/wheel
    chmod 440 /etc/sudoers.d/wheel

    # Add nushell as a valid shell
    grep -qxF /bin/nu /etc/shells || echo /bin/nu >> /etc/shells

    # Add user
    useradd -m -G wheel,audio,video,input,storage,network,socklog,docker -s /bin/nu "$USERNAME"

    echo "Please input password for root:"
    passwd root
    echo "Please input password for $USERNAME:"
    passwd "$USERNAME"

    # Move repo into user's home
    mv /tmp/dots "/home/$USERNAME/dots"
    chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/dots"

    # Link dotfiles
    su -s /bin/bash "$USERNAME" -c 'cd ~/dots && ./link.sh'

    cat > /etc/resolv.conf <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF

    xbps-reconfigure -fa
}

export MACHINE_HOSTNAME USERNAME REPO
xchroot /mnt /bin/bash -c "$(declare -f chroot_setup); chroot_setup"

# Cleanup
umount -R /mnt
sync

echo "Finished installing Void linux, now restart the system and remove the installer media"
exit 0
