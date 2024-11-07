#!/usr/bin/env bash

print_help() {
    printf "Usage:\n"
    printf "%2s%s\n" "" "$(basename $0) <options>"
    printf "\n"
    printf "Arch Linux installation script (LUKS, Btrfs, Systemd-boot)\n"
    printf "\n"
    printf "Options:\n"
    _pfmt1="%2s%-10s%s\n"
    printf "${_pfmt1}" "" "install" "run installation"
    printf "${_pfmt1}" "" "check" "check target disk and passwords"
    printf "${_pfmt1}" "" "genmirrors" "write cn mirror servers to list"
    printf "${_pfmt1}" "" "help" "print this help"
    printf "\n"
    printf "How to set target disk and passwords:\n"
    _pfmt2="%2s%s\n"
    printf "${_pfmt2}" "" "run \`lsblk -dp\` to list available disk"
    printf "${_pfmt2}" "" "run \`export _archdisk=...\` to set target disk"
    printf "${_pfmt2}" "" "run \`export _lukspass=...\` to set LUKS password"
    printf "${_pfmt2}" "" "run \`export _rootpass=...\` to set root password"
    printf "${_pfmt2}" "" "run \`export _username=...\` to set root password"
    printf "${_pfmt2}" "" "run \`export _userpass=...\` to set root password"
}

genmirrors() {
    _mlist=/etc/pacman.d/mirrorlist
    if [[ ! -e ${_mlist}.old ]]; then
        cp ${_mlist} ${_mlist}.old
cat > ${_mlist} << EOB
Server = https://mirrors.aliyun.com/archlinux/\$repo/os/\$arch
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch
Server = https://mirrors.ustc.edu.cn/archlinux/\$repo/os/\$arch
EOB
    fi
}

init_variables() {
    if [[ -z ${_lukspass} ]]; then
        _lukspass=pass
    fi
    if [[ -z ${_rootpass} ]]; then
        _rootpass=pass
    fi
    if [[ -z ${_username} ]]; then
        _username=uuu
    fi
    if [[ -z ${_userpass} ]]; then
        _userpass=pass
    fi
    _efipart=/dev/disk/by-partlabel/efip
    _rootpart=/dev/disk/by-partlabel/rootp
    _luksroot=/dev/mapper/luksroot
}

init_variables

check_variables() {
    echo "_archdisk=${_archdisk}"
    echo "_lukspass=${_lukspass}"
    echo "_rootpass=${_rootpass}"
    echo "_username=${_username}"
    echo "_userpass=${_userpass}"
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

open_luks() {
    if [[ ! -e ${_luksroot} ]]; then
        printf "${_lukspass}" | cryptsetup open ${_rootpart} luksroot -d -
    fi
}

clear_mounts() {
    umount ${_efipart} &>/dev/null
    umount -AR /mnt &>/dev/null
    cryptsetup close ${_luksroot} &>/dev/null
}

partition_disk() {
    is_disk_set
    is_superuser

    # partition disk
    parted -s ${_archdisk} \
        mklabel gpt \
        mkpart efip fat32 1MiB 1025MiB \
        set 1 esp on \
        mkpart rootp ext4 1025MiB 100% \
        type 2 4f68bce3-e8cd-4db1-96e7-fbcaf984b709

    # format EFI
    mkfs.fat -F32 /dev/disk/by-partlabel/efip

    # format LUKS
    printf "${_lukspass}" | cryptsetup luksFormat ${_rootpart} -d -
    # open LUKS
    open_luks

    # format Btrfs
    mkfs.btrfs ${_luksroot}
    mount ${_luksroot} /mnt
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@var
    btrfs subvolume create /mnt/@data
    umount /mnt
}

clear_root_subvol() {
    open_luks
    mount ${_luksroot} /mnt
    rm -rf /mnt/@/*
    rm -rf /mnt/@var/*
    umount /mnt
}

mountfs() {
    is_disk_set
    is_superuser

    open_luks

    # mount filesystems
    mount -o subvol=@ ${_luksroot} /mnt
    mount -o subvol=@home --mkdir ${_luksroot} /mnt/home
    mount -o subvol=@var --mkdir ${_luksroot} /mnt/var
    mount -o subvol=@data --mkdir ${_luksroot} /mnt/data
    mount --mkdir /dev/disk/by-partlabel/efip /mnt/efi
}

install_packages() {
    # microcode
    _cpu=$(grep vendor_id /proc/cpuinfo)
    if [[ "${_cpu}" == *"AuthenticAMD"* ]]; then
        _microcode="amd-ucode"
    else
        _microcode="intel-ucode"
    fi

    # essential packages
    pacstrap -K /mnt base linux ${_microcode} linux-firmware btrfs-progs neovim \
        zram-generator networkmanager terminus-font plymouth sudo\
        man-db man-pages texinfo
}

write_fstab() {
    _efiuuid=$(blkid -s UUID -o value ${_efipart})
    _luksuuid=$(blkid -s UUID -o value ${_luksroot})
cat >> /mnt/etc/fstab << EOB
UUID=${_efiuuid} /efi vfat defaults 0 2
UUID=${_luksuuid} /     btrfs compress=zstd,subvol=/@     0 0
UUID=${_luksuuid} /home btrfs compress=zstd,subvol=/@home 0 0
UUID=${_luksuuid} /var  btrfs compress=zstd,subvol=/@var  0 0
UUID=${_luksuuid} /data btrfs compress=zstd,subvol=/@data 0 0
EOB
}

configure_packages() {
    # swap on zram
cat > /mnt/etc/systemd/zram-generator.conf << EOB
[zram0]
zram-size = min(ram, 8192)
compression-algorithm = zstd
EOB
    # NetworkManager
    systemctl enable NetworkManager --root=/mnt

    # console font
    echo "FONT=ter-132b" >> /mnt/etc/vconsole.conf

    # splash screen (plymouth)
    printf "[Daemon]\nTheme=spinner\n" >> /mnt/etc/plymouth/plymouthd.conf

    # sudo
    echo 'Defaults env_keep += "http_proxy https_proxy no_proxy"' > /mnt/etc/sudoers.d/sudoers
    echo "%wheel ALL=(ALL:ALL) ALL" >> /mnt/etc/sudoers.d/sudoers
}

run_chroot() {
arch-chroot /mnt /usr/bin/bash -e << EOB
# -e exit immediately on any error

# time
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc

# localization
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# hostname
echo "arch" > /etc/hostname

# initramfs
sed -i \
    '/^HOOKS=/c\HOOKS=(base systemd plymouth autodetect microcode modconf kms keyboard sd-vconsole sd-encrypt block filesystems fsck)' \
    /etc/mkinitcpio.conf
mkinitcpio -P

# systemd-boot
bootctl install
systemctl enable systemd-boot-update.service

# boot files
mkdir -p /efi/EFI/arch
cp -a /boot/vmlinuz-linux /efi/EFI/arch/
cp -a /boot/initramfs-linux.img /efi/EFI/arch/
cp -a /boot/initramfs-linux-fallback.img /efi/EFI/arch/

EOB
}

boot_files_auto_update() {
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
}

boot_loader_config() {
cat >> /mnt/efi/loader/loader.conf << EOB
default arch.conf
timeout 0
console-mode max
editor no
EOB

cat > /mnt/efi/loader/entries/arch.conf << EOB
title Arch Linux
linux /EFI/arch/vmlinuz-linux
initrd /EFI/arch/initramfs-linux.img
options rootflags=subvol=@ quiet splash
EOB

cat > /mnt/efi/loader/entries/arch-fallback.conf << EOB
title Arch Linux (fallback initramfs)
linux /EFI/arch/vmlinuz-linux
initrd /EFI/arch/initramfs-linux-fallback.img
options rootflags=subvol=@ quiet splash
EOB
}

move_pacmandb() {
    sed -i '/^#DBPath/a\DBPath=/usr/pacman' /mnt/etc/pacman.conf
    mv /mnt/var/lib/pacman /mnt/usr/pacman
}

set_root_password() {
    echo "root:${_rootpass}" | arch-chroot /mnt chpasswd
}

create_user() {
    arch-chroot /mnt useradd -m -G wheel -s /bin/bash ${_username}
    echo "${_username}:${_userpass}" | arch-chroot /mnt chpasswd
}

run_install() {
    is_disk_set
    is_superuser

    clear_mounts
    if [[ ! -e ${_efipart} ]]; then
        partition_disk
    fi
    clear_root_subvol
    mountfs
    install_packages
    write_fstab
    configure_packages
    run_chroot
    boot_files_auto_update
    boot_loader_config
    move_pacmandb
    set_root_password
    create_user
}

case ${1} in
    install)
        genmirrors
        run_install
        ;;
    check)
        check_variables
        exit 0
        ;;
    genmirrors)
        genmirrors
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

