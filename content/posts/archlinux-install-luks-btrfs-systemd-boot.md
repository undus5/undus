+++
title       = "Arch Linux Install: LUKS + Btrfs + Systemd-boot"
aliases     = "/posts/archlinux-install-btrfs-luks-systemd-boot/"
lastmod     = 2025-05-16
date        = 2024-10-28
showSummary = true
showTOC     = true
weight      = 1000
+++

Joining in the "btw" club, and stopped distro hopping finally.

<!--more-->

## Background

The reason someone always do distro hopping is they actually don't know what options
are there to choose, then always be distracted from shining fancy components. 
This is the most thing I learned after reading through the ArchWiki.

It took me roughly a month searching and thinking about the wiki, when finished,
I realized 2 things. One, I have designed my own workstation build during this process.
Two, I could implement this build on top of nearly any distros now, distro is
not a problem for me anymone.

If you still do distro hopping and want to settle down, go reading through the
ArchWiki, you will get answers, this is my advice.

## Official Guide

[Installation guide - ArchWiki](https://wiki.archlinux.org/title/Installation_guide)

## Preparation

[Download](https://archlinux.org/download/) Arch ISO, create bootable USB using
[ventoy](https://www.ventoy.net/en/index.html) or [rufus](https://rufus.ie/en/),
disable Secure Boot, boot ISO.

Enlarge console font by running command `setfont ter-132b` if needed.

The reflector didn't work well for me, I had to pick mirror servers manually
then wrote to the mirrorlist:

```
# cat > /etc/pacman.d/mirrorlist << EOB
Server = https://mirrors.aliyun.com/archlinux/\$repo/os/\$arch
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch
Server = https://mirrors.ustc.edu.cn/archlinux/\$repo/os/\$arch
EOB
```

## Partition Disk

"When using GPT, it is advised to follow the
[Discoverable Partitions Specification](https://uapi-group.org/specifications/specs/discoverable_partitions_specification/)
since [systemd-gpt-auto-generator](https://wiki.archlinux.org/title/Systemd#GPT_partition_automounting)
can automount them. The EFI system partition, XBOOTLDR partition,
swap partition and home partition types can be changed using the set command,
while for the root partition and others, you will need to specify the partition type UUID manually with the type command."\
Ref: [Parted#Partition schemes](https://wiki.archlinux.org/title/Parted#Partition_schemes)

"EFI system partition on a [GUID Partition Table](https://en.wikipedia.org/wiki/GUID_Partition_Table#Partition_type_GUIDs)
is identified by the partition type GUID c12a7328-f81f-11d2-ba4b-00a0c93ec93b.
Parted can set it automatically, create a partition with fat32 as the file system type and set the esp flag on it."\
Ref: [EFI system partition#GPT partitioned disks](https://wiki.archlinux.org/title/EFI_system_partition#GPT_partitioned_disks),
[Parted#UEFI/GPT examples](https://wiki.archlinux.org/title/Parted#UEFI/GPT_examples)

"Root partition type GUID should be "root partition" not "LUKS partition", which is
4f68bce3-e8cd-4db1-96e7-fbcaf984b709."\
Ref: [dm-crypt/Encrypt an entire system/Configuring the boot loader](https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#Configuring_the_boot_loader)

"Partition alignment need to be handled manually with parted."\
Ref: [Parted#Alignment](https://wiki.archlinux.org/title/Parted#Alignment)

"Disk file name would be like /dev/sda, /dev/nvme0n1, /dev/mmcblk0, /dev/vda."\
Ref: [Device file#Block devices](https://wiki.archlinux.org/title/Device_file#Block_devices)

```
# parted /dev/vda
(parted) mklabel gpt
(parted) mkpart efipart fat32 1MiB 1025MiB
(parted) set 1 esp on
(parted) mkpart cryptpart ext4 1025MiB 100%
(parted) type 2 4f68bce3-e8cd-4db1-96e7-fbcaf984b709
(parted) quit
```

All partitions that have partition labels are listed in the /dev/disk/by-partlabel directory.\
Ref: [Persistent block device naming#by-partlabel](https://wiki.archlinux.org/title/Persistent_block_device_naming#by-partlabel)

```
# ls -l /dev/disk/by-partlabel
total 0
lrwxrwxrwx 1 root root ... efipart -> ../../vda1
lrwxrwxrwx 1 root root ... rootpart -> ../../vda2
```

## EFI Partition

Ref:
[EFI system partition#Format the partition](https://wiki.archlinux.org/title/EFI_system_partition#Format_the_partition)

```
# mkfs.fat -F32 /dev/disk/by-partlabel/efipart
```

## LUKS

Ref:
[dm-crypt/Device encryption#Formatting LUKS partitions](https://wiki.archlinux.org/title/Dm-crypt/Device_encryption#Formatting_LUKS_partitions) ,\
[dm-crypt/Device encryption#Unlocking/Mapping LUKS partitions with the device mapper](https://wiki.archlinux.org/title/Dm-crypt/Device_encryption#Unlocking/Mapping_LUKS_partitions_with_the_device_mapper)

Format LUKS partition and open:

```
# cryptsetup luksFormat /dev/disk/by-partlabel/rootpart
# cryptsetup open /dev/disk/by-partlabel/rootpart root
# ls /dev/mapper/root
```

## Btrfs

Ref:
[Btrfs#File system on a single device](https://wiki.archlinux.org/title/Btrfs#File_system_on_a_single_device)
, [Btrfs#Subvolumes](https://wiki.archlinux.org/title/Btrfs#Subvolumes)
, [Snapper#Suggested filesystem layout](https://wiki.archlinux.org/title/Snapper#Suggested_filesystem_layout)

Create Btrfs filesystem:

```
# mkfs.btrfs /dev/mapper/root
# mount /dev/mapper/root /mnt

# btrfs subvolume create /mnt/@
# btrfs subvolume create /mnt/@home
# btrfs subvolume create /mnt/@var
# btrfs subvolume create /mnt/@data
# umount /mnt
```

There's a bit extra work needed to let @var subvolume work without issue, demonstrated
at section [Move PacmanDB](#move-pacmandb) of this post.

## Mount Filesystem

Ref:
[Btrfs#Compression](https://wiki.archlinux.org/title/Btrfs#Compression)
, [EFI system partition#Typical mount points](https://wiki.archlinux.org/title/EFI_system_partition#Typical_mount_points)

```
# mount -o subvol=@ /dev/mapper/root /mnt
# mount -o subvol=@home --mkdir /dev/mapper/root /mnt/home
# mount -o subvol=@var --mkdir /dev/mapper/root /mnt/var
# mount -o subvol=@data --mkdir /dev/mapper/root /mnt/data

# mount --mkdir /dev/disk/by-partlabel/efipart /mnt/efi
```

## Base Pkgs Configs

Ref:
[Installation guide#Install essential packages](https://wiki.archlinux.org/title/Installation_guide#Install_essential_packages)

### Kernel

CPU microcode updates `amd-ucode` or `intel-ucode` for hardware bug and security fixes:

```
# pacstrap -K /mnt \
    base mkinitcpio linux linux-lts linux-firmware btrfs-progs iptables-nft \
    amd-ucode neovim
```

`-K` means to initialize an empty pacman keyring in the target, so only adding it at first running.\
Ref: [pacstrap(8)](https://man.archlinux.org/man/pacstrap.8)

The latest kernel sometimes may cause annoying bugs like [this](https://github.com/systemd/systemd/issues/33083),
so setting LTS kernel as a fallback option would be a good choice.

### Swap on Zram

Ref: [Zram#Using zram-generator](https://wiki.archlinux.org/title/Zram#Using_zram-generator)

```
# pacstrap /mnt zram-generator
```

Create `/mnt/etc/systemd/zram-generator.conf` with:

```
[zram0]
zram-size = min(ram, 8192)
compression-algorithm = zstd
```

### Sudo

Ref: [Sudo#Environment variables](https://wiki.archlinux.org/title/Sudo#Environment_variables)
, [Sudo#Example entries](https://wiki.archlinux.org/title/Sudo#Example_entries)
, [Sudo#Tips and tricks](https://wiki.archlinux.org/title/Sudo#Tips_and_tricks)

```
# pacstrap /mnt sudo bash-completion
```

Create `/mnt/etc/sudoers.d/sudoers` with:

```
Defaults passwd_timeout = 0
Defaults timestamp_type = global
Defaults timestamp_timeout = 15
Defaults editor = /usr/bin/nvim
%wheel ALL=(ALL:ALL) ALL
```

### Console Font

```
# pacstrap /mnt terminus-font
# echo "FONT=ter-132b" >> /mnt/etc/vconsole.conf
```

### Utilities

```
# pacstrap /mnt \
    base-devel pacman-contrib \
    man-db man-pages texinfo \
    iwd git rsync
```

[iwd](https://wiki.archlinux.org/title/Iwd) is a wireless network management tool.

### Move PacmanDB

The pacman database in /var/lib/pacman must stay on the root subvolume `@`.\
Ref: [Snapper#Suggested filesystem layout](https://wiki.archlinux.org/title/Snapper#Suggested_filesystem_layout)

So, to keep /var as a separate btrfs subvolume, we need to move pacman database out of /var:

```
# sed -i '/^#DBPath/a\DBPath=/usr/pacmandb' /etc/pacman.conf
# mv /var/lib/pacman /usr/pacmandb
```

### Disable Watchdogs

```
# cat > /mnt/etc/modprobe.d/nowatchdogs.conf << EOB
blacklist iTCO_wdt
blacklist sp5100_tco
EOB
```

## Fstab

"When using encrypted containers with dm-crypt, the labels of filesystems inside of
containers are not available while the container is locked/encrypted."\
Ref: [Persistent block device naming#by-label](https://wiki.archlinux.org/title/Persistent_block_device_naming#by-label)

"The advantage of using the UUID method is that it is much less likely that name collisions occur than with labels.
Further, it is generated automatically on creation of the filesystem.
It will, for example, stay unique even if the device is plugged into another system
(which may perhaps have a device with the same label)."\
Ref: [Persistent block device naming#by-uuid](https://wiki.archlinux.org/title/Persistent_block_device_naming#by-uuid)

"It is preferable to mount using subvol=/path/to/subvolume, rather than the subvolid,
as the subvolid may change when restoring snapshots, requiring a change of mount configuration."\
Ref: [Btrfs#Mounting subvolumes](https://wiki.archlinux.org/title/Btrfs#Mounting_subvolumes)

Since `genfstab` would generate subvolid and other redundant options, I choose to write fstab manually.

Save partitions UUID to temp files for later use:

```
# blkid -s UUID -o value /dev/vda1 > /tmp/efiuuid
# blkid -s UUID -o value /dev/mapper/root > /tmp/luksuuid
```

Edit `/mnt/etc/fstab` with:

```
UUID=XXXX-XXXX /efi vfat defaults 0 2
UUID=xxxxxxxx-...-xxxxxxxxxxxx / btrfs compress=zstd,subvol=/@ 0 0
UUID=xxxxxxxx-...-xxxxxxxxxxxx /home btrfs compress=zstd,subvol=/@home 0 0
UUID=xxxxxxxx-...-xxxxxxxxxxxx /var btrfs compress=zstd,subvol=/@var 0 0
UUID=xxxxxxxx-...-xxxxxxxxxxxx /data btrfs compress=zstd,subvol=/@data 0 0
```

## Networking

### Systemd-networkd

Ref:
[Network configuration#Network management](https://wiki.archlinux.org/title/Network_configuration#Network_management)

"For system with multiple network interfaces that are not expected to be connected
all the time (e.g. if a dual-port Ethernet card, but only one cable plugged in),
starting systemd-networkd-wait-online.service will fail after the default timeout of 2 minutes.
This may cause an unwanted delay in the startup process. To change the behaviour to
wait for any interface rather than all interfaces to become online,
edit the service and add the --any parameter to the ExecStart line:"

```
# _waitdir=/mnt/etc/systemd/system/systemd-networkd-wait-online.service.d
# mkdir -p ${_waitdir}
# cat > ${_waitdir}/wait-for-only-one-interface.conf << EOB
[Service]
ExecStart=
ExecStart=/usr/lib/systemd/systemd-networkd-wait-online --any
EOB
```

Ref:
[Systemd-networkd#systemd-networkd-wait-online](https://wiki.archlinux.org/title/Systemd-networkd#systemd-networkd-wait-online)

Run `ip link show` to list network devices, write configs for them:

```
# cat > /mnt/etc/systemd/network/23-enp0s1.network << EOB
[Match]
Name=enp0s1
[Link]
RequiredForOnline=routable
[Network]
DHCP=yes
[DHCPv4]
RouteMetric=100
[IPV6AcceptRA]
RouteMetric=100
EOB

# cat > /mnt/etc/systemd/network/27-wireless.network << EOB
[Match]
Name=wlan0
[Link]
RequiredForOnline=routable
[Network]
DHCP=yes
IgnoreCarrierLoss=3s
[DHCPv4]
RouteMetric=600
[IPV6AcceptRA]
RouteMetric=600
EOB

```

Ref:
[Systemd-networkd#Wired and wireless adapters on the same machine](https://wiki.archlinux.org/title/Systemd-networkd#Wired_and_wireless_adapters_on_the_same_machine)

"IgnoreCarrierLoss=3s ensures that systemd-networkd will not re-configure the interface
(e.g., release and re-acquire a DHCP lease) for a short period (3 seconds in this example)
while the wireless interface roams to another access point within the same wireless network (SSID),
which translates to shorter downtime when roaming."

Ref:
[Systemd-networkd#Wireless adapter](https://wiki.archlinux.org/title/Systemd-networkd#Wireless_adapter)

Systemd-networkd does not set per-interface-type default route metrics.
If you have multiple network cards of same type, say 2 wired network cards,
you must specific different `RouteMetric` for them, or the "race condition"
will cause extreamly slow network connections.

Ref:
[Systemd-networkd#Prevent multiple default routes](https://wiki.archlinux.org/title/Systemd-networkd#Prevent_multiple_default_routes)

If you have custom routing configs, you must disable `ManageForeignRoutingPolicyRules` option,
because it will remove rules that are not configured in .network files by default.

"systemd-networkd will alter routing tables also for other network software.
If this is undesired, configure ManageForeignRoutingPolicyRules= in
[networkd.conf(5)](https://man.archlinux.org/man/networkd.conf.5.en#%5BNETWORK%5D_SECTION_OPTIONS)
accordingly.
For example, see
[WireGuard#Connection lost after sleep using systemd-networkd](https://wiki.archlinux.org/title/WireGuard#Connection_lost_after_sleep_using_systemd-networkd)"

```
# sed -i '/^\[Network/a\ManageForeignRoutingPolicyRules=no' \
    /mnt/etc/systemd/networkd.conf
```

Ref:
[Systemd-networkd#Configuration files](https://wiki.archlinux.org/title/Systemd-networkd#Configuration_files)

Enable systemd-networkd.service:

```
# systemctl enable systemd-networkd.service --root=/mnt
```

### Systemd-resolved

Enable systemd-resolved.service to let DNS work:

```
# systemctl enable systemd-resolved.service --root=/mnt
```

Ref:
[Systemd-resolved](https://wiki.archlinux.org/title/Systemd-resolved)

## Chroot

```
# arch-chroot /mnt
```

Time:

```
# ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
# hwclock --systohc
# systemctl enable systemd-timesyncd.service
```

Localization:

```
# echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
# echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen
# locale-gen
# echo "LANG=en_US.UTF-8" >> /etc/locale.conf
```

Hostname:

```
# echo "archlinux" > /etc/hostname
```

Remap CapsLock to Control for console.\
Ref: [Linux console/Keyboard configuration#Creating a custom keymap](https://wiki.archlinux.org/title/Linux_console/Keyboard_configuration#Creating_a_custom_keymap)

```
# _kmapdir=/mnt/usr/share/kbd/keymaps/i386/qwerty
# gzip -dc < ${_kmapdir}/us.map.gz > ${_kmapdir}/usa.map
# sed -i '/^keycode[[:space:]]58/c\keycode 58 = Control' \
    ${_kmapdir}/usa.map
# echo "KEYMAP=usa" >> /mnt/etc/vconsole.conf
```

Enable multilib repo.
Ref: [General recommendations#Repositories](https://wiki.archlinux.org/title/General_recommendations#Repositories)

```
# cat >> /mnt/etc/pacman.conf << EOB
[multilib]
Include = /etc/pacman.d/mirrorlist
EOB
```

Root Password:

```
# passwd
```

Create User:
```
# useradd -m -G wheel -s /bin/bash user1
# passwd user1
```

## Initramfs

Ref: [dm-crypt/System configuration#mkinitcpio](https://wiki.archlinux.org/title/Dm-crypt/System_configuration#mkinitcpio)

Edit `/etc/mkinitcpio.conf`:

```
HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole sd-encrypt block filesystems fsck)
```

Recreate initramfs image:

```
# mkinitcpio -P
```

## Systemd-boot

Install UEFI boot manager.\
Ref: [Systemd-boot#Installing the UEFI boot manager](https://wiki.archlinux.org/title/Systemd-boot#Installing_the_UEFI_boot_manager)
, [Systemd-boot#systemd service](https://wiki.archlinux.org/title/Systemd-boot#systemd_service)

```
bootctl install
systemctl enable systemd-boot-update.service
```

### Boot Files

Copy boot files to ESP.\
Ref: [EFI system partition#Alternative mount points](https://wiki.archlinux.org/title/EFI_system_partition#Alternative_mount_points)

```
# mkdir -p /efi/EFI/arch
# cp -a /boot/vmlinuz-linux /efi/EFI/arch/
# cp -a /boot/initramfs-linux.img /efi/EFI/arch/
# cp -a /boot/vmlinuz-linux-lts /efi/EFI/arch/
# cp -a /boot/initramfs-linux-lts.img /efi/EFI/arch/
```

Auto update boot files under ESP with systemd.\
Ref: [EFI system partition#Using systemd](https://wiki.archlinux.org/title/EFI_system_partition#Using_systemd)
, [systemd.path(5)](https://man.archlinux.org/man/systemd.path.5)

Create `/etc/systemd/system/efistub-update.path`

```
[Unit]
Description=Copy EFISTUB Kernel to EFI system partition
[Path]
PathChanged=/boot/initramfs-linux-fallback.img
[Install]
WantedBy=multi-user.target
WantedBy=system-update.target
```

Create `/etc/systemd/system/efistub-update.service`

```
[Unit]
Description=Copy EFISTUB Kernel to EFI system partition
[Service]
Type=oneshot
ExecStart=/usr/bin/cp -af /boot/vmlinuz-linux /efi/EFI/arch/
ExecStart=/usr/bin/cp -af /boot/initramfs-linux.img /efi/EFI/arch/
ExecStart=/usr/bin/cp -af /boot/vmlinuz-linux-lts /efi/EFI/arch/
ExecStart=/usr/bin/cp -af /boot/initramfs-linux-lts.img /efi/EFI/arch/
```

Enable systemd units:

```
# systemctl enable efistub-update.{path,service}
```

### Boot Loader

Ref: [Systemd-boot#Configuration](https://wiki.archlinux.org/title/Systemd-boot#Configuration)

Edit `/efi/loader/loader.conf`:

```
default arch.conf
timeout 0
console-mode max
editor no
```

`timeout 0` means not showing menu and boot immediately.

Create `/efi/loader/entries/arch.conf`.

```
title Arch Linux
linux /EFI/arch/vmlinuz-linux
initrd /EFI/arch/initramfs-linux.img
options rootflags=subvol=@ quiet
```

To use a subvolume as the root mountpoint, specify the subvolume via a kernel parameter
using rootflags=subvol=@. Or you would get an error "Failed to start Switch Root" when booting.\
Ref: [Btrfs#Mounting subvolume as root](https://wiki.archlinux.org/title/Btrfs#Mounting_subvolume_as_root)

Create `/efi/loader/entries/arch-lts.conf`.

```
title Arch Linux LTS
linux /EFI/arch/vmlinuz-linux-lts
initrd /EFI/arch/initramfs-linux-lts.img
options rootflags=subvol=@ quiet
```

Note: If disk partitions were not following
[Discoverable Partitions Specification](https://uapi-group.org/specifications/specs/discoverable_partitions_specification/)
, which means root partition would not be discovered and auto mounted, booting system would stuck at
`a start job is running for /dev/gpt-auto-root` and timeout. To fix this, specify root partition in kernel parameters.\
Ref: [dm-crypt/Encrypting an entire system#Configuring the boot loader](https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#Configuring_the_boot_loader),\
[dm-crypt/System configuration#rd.luks.name](https://wiki.archlinux.org/title/Dm-crypt/System_configuration#rd.luks.name)

```
options rd.luks.name=<UUID>=root root=/dev/mapper/root rootflags=subvol=@ quiet
```

Ref: [Improving performance#Watchdogs](https://wiki.archlinux.org/title/Improving_performance#Watchdogs)
, [Kernel module#Blacklisting](https://wiki.archlinux.org/title/Kernel_module#Blacklisting)

## Snapshot

We can use pacman hooks to automatically create backup when upgrading system.

Create `/usr/local/bin/snapshot.sh` which do the job:

```
#!/usr/bin/bash
set -e
[[ ${EUID} == 0 ]] || (echo "run as root" && exit 1)
_shotsdir=/home/snapshots
mkdir -p ${_shotsdir}
printf "=== Cleaning old snapshots ..."
_shots=(${_shotsdir}/*)
for ((i=${#_shots[@]}-2; i>=0; i--)); do
    rm -rf ${_shots[$i]}
done
printf " Done.\n"
btrfs subvolume snapshot -r / ${_shotsdir}/@$(date +%Y%m%d%H%M%S)$(date +%N|cut -c1)
```

Make it executable:

```
# chmod +x /usr/local/bin/snapshot.sh
```

Create `/etc/pacman.d/hooks/snapshot-before-upgrade.hook`,
(create hooks directory manually if necessary):

```
[Trigger]
Operation = Upgrade
Type = Package
Target = linux
[Action]
Depends = btrfs-progs
When = PreTransaction
Exec = /usr/local/bin/snapshot.sh
```

This hook will be triggerd when the kernel package `linux` being upgraded.

Ref: [Btrfs#Snapshots](https://wiki.archlinux.org/title/Btrfs#Snapshots)
, [alpm-hooks(5)](https://man.archlinux.org/man/alpm-hooks.5)

## Reboot

```
# exit
# reboot
```

In case you've lost track of the installation process and want to start over, here's
some commands that can help you reset disk state, then you can retry installation.\
Ref: [dm-crypt/Drive preparation#Wipe LUKS header](https://wiki.archlinux.org/title/Dm-crypt/Drive_preparation#Wipe_LUKS_header)

```
# umount /mnt/efi
# umount -AR /mnt
# cryptsetup close /dev/mapper/root
# cryptsetup erase /dev/vda2
# wipefs -a /dev/vda
```

