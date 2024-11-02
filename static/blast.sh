#!/usr/bin/env bash

print_help() {
    printf "Usage:\n"
    printf "%2s%s\n" "" "$(basename $0) <options>"
    printf "\n"
    printf "Arch Linux installation script (LUKS, Btrfs, Systemd-boot)\n"
    printf "\n"
    printf "Options:\n"
    _pfmt1="%2s%-10s%s\n"
    printf "${_pfmt1}" "" "check" "check target disk and passwords"
    printf "${_pfmt1}" "" "install" "run installation"
    printf "${_pfmt1}" "" "reset" "reset disk state to start over"
    printf "${_pfmt1}" "" "genmirror" "print prefered mirror servers"
    printf "${_pfmt1}" "" "help" "print this help"
    printf "\n"
    printf "How to set target disk and passwords:\n"
    _pfmt2="%2s%s\n"
    printf "${_pfmt2}" "" "run \`lsblk -dp\` to list available disk"
    printf "${_pfmt2}" "" "run \`export _archdisk=...\` to set target disk"
    printf "${_pfmt2}" "" "run \`export _lukspass=...\` to set LUKS password"
    printf "${_pfmt2}" "" "run \`export _rootpass=...\` to set root password"
}

print_variables() {
    echo "_archdisk=${_archdisk}"
    echo "_lukspass=${_lukspass}"
    echo "_rootpass=${_rootpass}"
}

is_disk_set() {
    if [[ -z ${_archdisk} ]]; then
        echo "'_archdisk' is empty, run \`$(basename $0) help\` to get help."
        exit 1
    fi
}

is_superuser() {
    if [[ ${EUID} != 0 ]]; then
        echo "run as root"
        exit 1
    fi
}

genmirror() {
    printf "Server = https://mirrors.aliyun.com/archlinux/$repo/os/$arch\n"
    printf "Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch\n"
    printf "Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch\n"
}

reset_disk() {
    is_disk_set
    is_superuser
    umount -AR /mnt &>/dev/null
    cryptsetup close /dev/mapper/luksroot &>/dev/null
    cryptsetup erase ${_archdisk}
    wipefs -a ${_archdisk}
}

init_passwords() {
    if [[ -z ${_lukspass} ]]; then
        _lukspass=pass
    fi
    if [[ -z ${_rootpass} ]]; then
        _rootpass=pass
    fi
}

init_passwords

case ${1} in
    install)
        ;;
    check)
        print_variables
        exit 0
        ;;
    genmirror)
        genmirror
        exit 0
        ;;
    reset)
        reset_disk
        exit 0
        ;;
    help)
        print_help
        exit 0
        ;;
    *)
        print_help
        exit 1
        ;;
esac

is_superuser

################################################################################
## Partition disk
################################################################################
parted -s ${_archdisk} \
    mklabel gpt \
    mkpart efip fat32 1MiB 1025MiB \
    set 1 esp on \
    mkpart rootp ext4 1025MiB 100% \
    type 2 4f68bce3-e8cd-4db1-96e7-fbcaf984b709

################################################################################
## Format EFI partition
################################################################################
mkfs.fat -F32 /dev/disk/by-partlabel/efip

################################################################################
## LUKS
################################################################################
printf "${_lukspass}" | cryptsetup luksFormat /dev/disk/by-partlabel/rootp -d -
printf "${_lukspass}" | cryptsetup open /dev/disk/by-partlabel/rootp luksroot -d -

################################################################################
## Btrfs
################################################################################
mkfs.btrfs /dev/mapper/luksroot
mount /dev/mapper/luksroot /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@data
umount /mnt

################################################################################
## Mount filesystem
################################################################################
mount -o compress=zstd,subvol=@ /dev/mapper/luksroot /mnt
mount -o compress=zstd,subvol=@home --mkdir /dev/mapper/luksroot /mnt/home
mount -o compress=zstd,subvol=@var --mkdir /dev/mapper/luksroot /mnt/var
mount -o compress=zstd,subvol=@data --mkdir /dev/mapper/luksroot /mnt/data
mount --mkdir /dev/disk/by-partlabel/efip /mnt/efi

################################################################################
## Install packages
################################################################################

## Microcode
_cpu=$(grep vendor_id /proc/cpuinfo)
if [[ "${_cpu}" == *"AuthenticAMD"* ]]; then
    _microcode="amd-ucode"
else
    _microcode="intel-ucode"
fi

### Essential packages
pacstrap -K /mnt base linux ${_microcode} linux-firmware btrfs-progs zram-generator \
    neovim networkmanager terminus-font

### Set swap on zram
cat > /mnt/etc/systemd/zram-generator.conf << EOB
[zram0]
zram-size = min(ram, 8192)
compression-algorithm = zstd
EOB

### Set NetworkManager
systemctl enable NetworkManager --root=/mnt

### Console font
echo "FONT=ter-132b" >> /mnt/etc/vconsole.conf

## Fstab
genfstab -U /mnt >> /mnt/etc/fstab

################################################################################
## Chroot
################################################################################
### (-e Exit immediately on any error)
arch-chroot /mnt /usr/bin/bash -e << EOB

### Time
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc

### Localization
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

### Hostname
echo "archlinux" > /etc/hostname

### Initramfs
sed -i \
    '/^HOOKS=/c\HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole sd-encrypt block filesystems fsck)' \
    /etc/mkinitcpio.conf
mkinitcpio -P

## Systemd-boot
bootctl install
systemctl enable systemd-boot-update.service

## Boot files
mkdir -p /efi/EFI/arch
cp -a /boot/vmlinuz-linux /efi/EFI/arch/
cp -a /boot/initramfs-linux.img /efi/EFI/arch/
cp -a /boot/initramfs-linux-fallback.img /efi/EFI/arch/

EOB

################################################################################
## Auto update boot files
################################################################################

cat > /mnt/etc/systemd/system/efistub-update.path << EOB
[Unit]
Description=Copy EFISTUB Kernel to EFI system partition
[Path]
PathChanged=/boot/initramfs-linux-fallback.img
[Install]
WantedBy=multi-user.target
WantedBy=system-update.target
EOB

cat > /mnt/etc/systemd/system/efistub-update.service << EOB
[Unit]
Description=Copy EFISTUB Kernel to EFI system partition
[Service]
Type=oneshot
ExecStart=/usr/bin/cp -af /boot/vmlinuz-linux /efi/EFI/arch/
ExecStart=/usr/bin/cp -af /boot/initramfs-linux.img /efi/EFI/arch/
ExecStart=/usr/bin/cp -af /boot/initramfs-linux-fallback.img /efi/EFI/arch/
EOB

systemctl enable efistub-update.{path,service} --root=/mnt

################################################################################
## Boot loader
################################################################################

cat >> /mnt/efi/loader/loader.conf << EOB
default arch.conf
timeout 4
console-mode max
editor no
EOB

cat > /mnt/efi/loader/entries/arch.conf << EOB
title Arch Linux
linux /EFI/arch/vmlinuz-linux
initrd /EFI/arch/initramfs-linux.img
options rootflags=subvol=@
EOB

cat > /mnt/efi/loader/entries/arch-fallback.conf << EOB
title Arch Linux (fallback initramfs)
linux /EFI/arch/vmlinuz-linux
initrd /EFI/arch/initramfs-linux-fallback.img
options rootflags=subvol=@
EOB

################################################################################
## Move pacman database
################################################################################
sed -i '/^#DBPath/a\DBPath=/usr/pacman' /mnt/etc/pacman.conf
mv /mnt/var/lib/pacman /mnt/usr/pacman

################################################################################
## Root password
################################################################################
printf "root:${_rootpass}" | arch-chroot /mnt chpasswd

