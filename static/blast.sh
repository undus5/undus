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
        _rootpass=${_lukspass}
    fi
    if [[ -z ${_username} ]]; then
        _username=user1
    fi
    if [[ -z ${_userpass} ]]; then
        _userpass=${_lukspass}
    fi
    if [[ -z ${_hostname} ]]; then
        _hostname=archlinux
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
    echo "_hostname=${_hostname}"
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

install_base_pkgs() {
    # microcode
    _cpu=$(grep vendor_id /proc/cpuinfo)
    if [[ "${_cpu}" == *"AuthenticAMD"* ]]; then
        _microcode="amd-ucode"
    elif [[ "${_cpu}" == *"GenuineIntel"* ]]; then
        _microcode="intel-ucode"
    fi
    pacstrap -K /mnt base linux linux-firmware btrfs-progs ${_microcode}
}

install_zram() {
    pacstrap /mnt zram-generator
cat > /mnt/etc/systemd/zram-generator.conf << EOB
[zram0]
zram-size = min(ram, 8192)
compression-algorithm = zstd
EOB
}

install_networkmanager() {
    pacstrap /mnt networkmanager
    systemctl enable NetworkManager --root=/mnt
}

install_plymouth() {
    pacstrap /mnt plymouth
    printf "[Daemon]\nTheme=spinner\n" >> /mnt/etc/plymouth/plymouth.conf
}

install_console_fonts() {
    pacstrap /mnt terminus-font
    echo "FONT=ter-132b" >> /mnt/etc/vconsole.conf
}

install_desktop_fonts() {
    pacstrap /mnt noto-fonts noto-fonts-cjk noto-fonts-emoji
cat > /etc/fonts/local.conf << EOB
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
<alias>
    <family>sans-serif</family>
    <prefer>
        <family>Noto Sans</family>
        <family>Noto Sans CJK SC</family>
        <family>Noto Sans CJK TC</family>
        <family>Noto Sans CJK HK</family>
        <family>Noto Sans CJK JP</family>
        <family>Noto Sans CJK KR</family>
    </prefer>
</alias>
<alias>
    <family>serif</family>
    <prefer>
        <family>Noto Serif</family>
        <family>Noto Serif CJK SC</family>
        <family>Noto Serif CJK TC</family>
        <family>Noto Serif CJK HK</family>
        <family>Noto Serif CJK JP</family>
        <family>Noto Serif CJK KR</family>
    </prefer>
</alias>
<alias>
    <family>monospace</family>
    <prefer>
        <family>Noto Sans Mono</family>
        <family>Noto Sans Mono CJK SC</family>
        <family>Noto Sans Mono CJK TC</family>
        <family>Noto Sans Mono CJK HK</family>
        <family>Noto Sans Mono CJK JP</family>
        <family>Noto Sans Mono CJK KR</family>
    </prefer>
</alias>
</fontconfig>
EOB
}

install_pipewire() {
    pacstrap /mnt alsa-utils \
        pipewire wireplumber \
        pipewire-alsa pipewire-pulse pipewire-jack lib32-pipewire
}

install_utilities() {
    pacstrap /mnt \
        man-db man-pages texinfo \
        pacman-contrib base-devel git rsync \
        neovim

    echo "EDITOR=/usr/bin/nvim" >> /mnt/etc/profile.d/profile.sh
}

install_sudo() {
    pacstrap /mnt sudo bash-completion
cat > /mnt/etc/sudoers.d/sudoers << EOB
%wheel ALL=(ALL:ALL) ALL
Defaults passwd_timeout = 0
Defaults timestamp_type = global
Defaults timestamp_timeout = 15
Defaults env_keep += "http_proxy https_proxy no_proxy"
Defaults editor = /usr/bin/nvim
EOB
    # fix tab completion
    echo "alias sudo='sudo '" >> /mnt/etc/profile.d/profile.sh
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

set_timezone() {
arch-chroot /mnt /usr/bin/bash -e << EOB
# (-e exit immediately on any error)
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc
EOB
}

set_localization() {
    echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen
    echo "zh_CN.UTF-8 UTF-8" >> /mnt/etc/locale.gen
    arch-chroot /mnt locale-gen
    echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
}

set_hostname() {
    echo ${_hostname} > /mnt/etc/hostname
}

set_keymap() {
    # remap capslock to control
    _kmapdir=/mnt/usr/share/kbd/keymaps/i386/qwerty
    gzip -dc < ${_kmapdir}/us.map.gz > ${_kmapdir}/usa.map
    sed -i '/^keycode[[:space:]]58/c\keycode 58 = Control' ${_kmapdir}/usa.map
    echo "KEYMAP=usa" >> /mnt/etc/vconsole.conf
}

enable_multilib() {
    printf "[multilib]\nInclude = /etc/pacman.d/mirrorlist\n" >> /mnt/etc/pacman.conf
}

enable_bbr() {
    echo "net.core.default_qdisc = cake" >> /mnt/etc/sysctl.d/99-bbr.conf
    echo "net.ipv4.tcp_congestion_control = bbr" >> /mnt/etc/sysctl.d/99-bbr.conf
}

recreate_initramfs() {
    sed -i \
        '/^HOOKS=/c\HOOKS=(base systemd plymouth autodetect microcode modconf kms keyboard sd-vconsole sd-encrypt block filesystems fsck)' \
        /mnt/etc/mkinitcpio.conf
    arch-chroot /mnt mkinitcpio -P
}

install_systemd_boot() {
    arch-chroot /mnt bootctl install
    systemctl enable systemd-boot-update.service --root=/mnt
}

copy_boot_files() {
    mkdir -p /mnt/efi/EFI/arch
    cp -a /mnt/boot/vmlinuz-linux /mnt/efi/EFI/arch/
    cp -a /mnt/boot/initramfs-linux.img /mnt/efi/EFI/arch/
    cp -a /mnt/boot/initramfs-linux-fallback.img /mnt/efi/EFI/arch/
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
options rootflags=subvol=@
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
    install_base_pkgs
    install_zram
    install_networkmanager
    install_plymouth
    install_console_fonts
    install_desktop_fonts
    install_pipewire
    install_utilities
    install_sudo
    write_fstab
    set_timezone
    set_localization
    set_hostname
    set_keymap
    enable_multilib
    enable_bbr
    recreate_initramfs
    install_systemd_boot
    copy_boot_files
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

