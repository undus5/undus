+++
title       = 'Linux Bootstrap Installation'
aliases     = ["/posts/bootstrap-install-any-linux-distro/"]
lastmod     = '2026-06-21'
date        = '2025-10-19'
tags        = ['linux']
showTOC     = true
showSummary = true
weight      = 1000
+++

Distro is trival, just learn the basics and build your own.

<!--more-->

## Series Index

1. Linux Bootstrap Installation
2. [Linux A/B System Updates via BTRFS Snapshot](/posts/linux-ab-system-updates-via-btrfs-snapshot/)
3. [Linux Post Installation](/posts/linux-post-installtion/)
4. [Linux Desktop: Sway, Labwc, GUI Apps](/posts/linux-desktop-sway-labwc-gui-apps/)
5. [Linux Live ISO Packaging](/posts/linux-live-iso-packaging/)

## Preface

Want to stop distro hopping? Sure, just go read through the
[ArchWiki](https://wiki.archlinux.org/title/Main_page). Don't get me wrong,
I'm not selling Arch Linux to you, just the wiki. The reason you always be 
distracted by shining fancy components from some new releases
or emerging distros, is that you don't have a big picture about linux and
its ecosystem, and you haven't figure out what you really need.
This is the most thing I learned after reading through the wiki.
When I finished reading, I learned what choices are there, and found my needs,
then built my own configurations.

In fact, you can install nearly all the linux distros manually in a similar way,
aka "the arch way", since the installers they offered are doing the same job
under the hood, but with less flexibility and more bloat. So if you want to
settle down, go read the wiki, learn the basics, then you can pick up whatever
distros you like and tweaking them to the shape you want, the only differences
are just package management system, release model and community support.

This guide is basically distro independent, since I don't like to be bound to
any specific platform in any form, always avoid using any distro specific tools,
try my best to maintain the portability. It's tested on Arch, Fedora and
Debian(Ubuntu), the differences are minor.

## Live ISO

You need a live iso image to boot into live system for doing installation. 

[Arch](https://archlinux.org/download/),
[Fedora](https://www.fedoraproject.org/),
[Debian](https://www.debian.org/)

To create bootable USB stick, use [Ventoy](https://www.ventoy.net/en/index.html)
or [Rufus](https://rufus.ie/en/).

## Partition Disk

In my experience, the best partition practice is to create a separate
[EFI system partition](https://wiki.archlinux.org/title/EFI_system_partition)
and a root partition with BTRFS filesystem, we will discuss BTRFS later.

We will follow the
[Discoverable Partitions Specification](https://uapi-group.org/specifications/specs/discoverable_partitions_specification/)
to let systemd automatically discover, mount and enable the root partition
based on GPT (GUID Partition Tables), by specifying dedicated UUIDs to partitions.

Using [Parted](https://wiki.archlinux.org/title/Parted) to do the job:

```
(root)# parted /dev/nvme0n1
(parted) mklabel gpt
(parted) mkpart EFIPART fat32 1MiB 1025MiB
(parted) set 1 esp on
(parted) mkpart ROOTPART btrfs 1025MiB 100%
(parted) type 2 4f68bce3-e8cd-4db1-96e7-fbcaf984b709
(parted) quit
```

Partitions need to be aligned to specific size for LUKS working correctly,
a typical practice is 1MiB. In our example, we assigned 2GB to the EFI partition,
the rest to the root partition, and aligned them to 1MiB.

Note that we specified the discoverable UUID for the root partition, but not for
the EFI partition, because it is done by the `esp on` commands.

## LUKS

Next we set [Device Encryption](https://wiki.archlinux.org/title/Dm-crypt/Device_encryption).
Even you don't want to bother typing another passphrase beside system
login password every time when booting up,
I still strongly recommend to configure it with a preset key file
(we will discuss this in later section), which do not
need you to enter passphrase, it will do decrypting automatically using the key file.
Although it is missing the point of disk encryption in this way, it will still
be beneficial, if your laptop is lost, this encryption
setting can prevent your data being read from random people, since
there's low possibility the person who picked your device is computer expert
with knowledges about Linux and LUKS.

You still need to set a passphrase when configuring LUKS,
save it carefully, may be use a password manager to store it,
[KeePass](https://wiki.archlinux.org/title/KeePass) is a good one.

After partitioning, you can locate partitions via their labels:

```
(root)# cryptsetup luksFormat /dev/disk/by-partlabel/ROOTPART
(root)# cryptsetup open /dev/disk/by-partlabel/ROOTPART root
(root)# ls /dev/mapper/root
```

Now the `ROOTPART` is encrypted, and must be decrypted via `cryptsetup open`
command to let it work, `/dev/mapper/root` is the decrypted root partition,
we will create filesystem on top of it.

## BTRFS

Ext4 may be the most solid filesystem, but
[BTRFS](https://wiki.archlinux.org/title/Btrfs)
is a better choice for personal use because of its modern features.

Recall the early days when I was learning and tinkering with linux, It was always
a hard decision on how much storage to allocate for the separate /home partition,
today with BTRFS, it's not a problem anymore. You could just create BTRFS subvolumes
for whatever directories you want to separate, they will share the whole storage
of the root partition, just like normal folders do.

```
(root)# mkfs.btrfs /dev/mapper/root
(root)# mount /dev/mapper/root /mnt
(root)# btrfs subvolume create /mnt/@
(root)# btrfs subvolume create /mnt/@home
(root)# umount /mnt

(root)# mount -o subvol=@ /dev/mapper/root /mnt
(root)# mount --mkdir -o subvol=@home /dev/mapper/root /mnt/home
(root)# mkfs.fat -F32 /dev/disk/by-partlabel/EFIPART
(root)# mount --mkdir /dev/disk/by-partlabel/EFIPART /mnt/efi
```

Another great BTRFS feature is it's easy to create snapshots by its
Copy on Write (CoW) nature, useful for creating backup against system crash.

## Repo Mirror

Check the online mirrorlist, pick proper one, then edit local mirrorlist config.

Arch: [Pacman Mirrorlist](https://archlinux.org/mirrorlist/),
local: `/etc/pacman.d/mirrorlist`\
Fedora: [Archive Mirrors](https://mirrormanager.fedoraproject.org),
local: `/etc/yum.repos.d/fedora.repo`\
Debian: [Debian Mirrors](https://www.debian.org/mirror/list),
local: `/etc/apt/sources.list`\
Ubuntu: [Archive Mirrors](https://launchpad.net/ubuntu/+archivemirrors)

## Base System

Now we are ready to install the base system. We will use a dedicated tool
to install base system packages into /mnt.

For package names in `$PKGS`, refers to
[hikerlinux/packages.sh](https://github.com/undus5/hikerlinux/blob/main/bootstrap/packages.sh)

For Arch it's
[Pacstrap](https://wiki.archlinux.org/title/Installation_guide#Install_essential_packages):

```
(root)# pacstrap -K /mnt $PKGS
```

For Fedora it's DNF:

```
(root)# dnf --use-host-config --releasever=44 --installroot=/mnt install $PKGS
```

For Debian it's [Debootstrap](https://wiki.debian.org/Debootstrap):

```
(root)# debootstrap --components=main,contrib,non-free,non-free-firmware \
    --include=$PKGS stable /mnt http://deb.debian.org/debian/
```

For Ubuntu:

```
(root)# debootstrap --components=main,restricted,universe,multiverse \
    --include=$PKGS resolute /mnt http://archive.ubuntu.com/ubuntu
```

## Fstab

Let's generate the [fstab](https://wiki.archlinux.org/title/Fstab)
before entering chroot system, since we need to get partition UUIDs from
live system. First we write partition UUIDs
to temporary text files using `blkid` command for later use, because typing UUID
manually is annoying and error prone, note the UUID for the root partition must
be the decrypted one, which is `/dev/mapper/root`, not the `ROOTPART`.

```
(root)# blkid -s UUID -o value /dev/mapper/root > /tmp/rootuuid.txt
(root)# blkid -s UUID -o value /dev/disk/by-partlabel/EFIPART > /tmp/efiuuid.txt
```

Then we edit `/mnt/etc/fstab`. If you use `nano` text editor, you can press
`Ctrl + r` to read UUID from temporary file, or if you use `vim`, you can run
`:r /tpm/rootuuid.txt` command to read UUID.

```
UUID=xxxxxxxx-...-xxxxxxxxxxxx /     btrfs compress=zstd,subvol=/@     0 0
UUID=xxxxxxxx-...-xxxxxxxxxxxx /home btrfs compress=zstd,subvol=/@home 0 0
UUID=XXXX-XXXX /efi vfat defaults 0 0
```

## Mount VFS

Mount virtual filesystems to `/mnt` for later chroot:

```
(root)# for DIR in dev proc run sys; do \
    mount --mkdir --rbind --make-rslave /$DIR /mnt/$DIR; done
```

## Chroot

```
(root)# chroot /mnt /bin/bash
```

## Time

```
(root)# ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
(root)# hwclock --systohc
(root)# systemctl enable systemd-timesyncd.service
```

## Localization

For Arch and Debian:

```
(root)# echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
(root)# echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen
(root)# locale-gen
```

For Fedora, they are provided by packages `glibc-langpack-en`,
`glibc-langpack-zh` or `glibc-all-langpacks`.

Set LANG variable:

```
(root)# echo "LANG=en_US.UTF-8" >> /etc/locale.conf
```

## Hostname

```
(root)# echo "archlinux" > /etc/hostname
```

## Root Password

```
(root)# passwd
```

## Zram

We have large memory storage nowadays, so just put the swap into RAM using
[zram](https://wiki.archlinux.org/title/Zram).

Create `/etc/systemd/zram-generator.conf`, the size is in MiB.

```
[zram0]
zram-size = min(ram/2, 8192)
compression-algorithm = zstd
```

## Systemd-Networkd

In my experience,
[systemd-networkd](https://wiki.archlinux.org/title/Systemd-networkd)
is better than NetworkManager especially for maintaining bridged network
interfaces for virtual machines.

Run `ip link show` command to get your network interface names,
for example: enp0s1, wlan0.

For wired network interface, create `/etc/systemd/network/20-lan.network`.

```
[Match]
Type=ether
Kind=!*
[Link]
RequiredForOnline=routable
[Network]
DHCP=yes
[DHCPv4]
RouteMetric=100
[IPv6AcceptRA]
RouteMetric=100
```

Note that `Type=ether` will also match virtual Ethernet interfaces. To exclude
them, use `Type=ether` in combination with `Kind=!*`.

For wireless network interface, create `/etc/systemd/network/35-wlan.network`.

```
[Match]
Type=wlan
[Link]
RequiredForOnline=routable
[Network]
DHCP=yes
IgnoreCarrierLoss=3s
[DHCPv4]
RouteMetric=600
[IPv6AcceptRA]
RouteMetric=600
```

Setting unique `RouteMetric` for different network interfaces is necessary,
or they will enter into "race condition", which will cause extreamly slow network
connections.

`RequiredForOnline=routable` is necessary to prevent
`systemd-networkd-wait-online.service` hanging the systemd boot process.

By default systemd would wait for all the network interfaces online,
if your computer have multiple network interfaces, it would be a problem, 
systemd services with `Requires=network-online.target` would not start properly.
To fix this, alter the `systemd-networkd-wait-online.service` by creating
`/etc/systemd/system/systemd-networkd-wait-online.service.d/override.conf` manually
or run `systemctl edit systemd-networkd-wait-online.service`:

```
[Service]
ExecStart=
ExecStart=/usr/lib/systemd/systemd-networkd-wait-online --any
```

You may need to disable `ManageForeignRoutingPolicyRules` option in
`/etc/systemd/networkd.conf`, since it will flush all your custom
rules that are not configured in `.network` units, such as the rules added
by `ip rule` command.

```
[Network]
ManageForeignRoutingPolicyRules=no
```

Enable the services.

```
(root)# systemctl enable systemd-networkd.service
```

Debian need to move out `/etc/network/interfaces` according to
[SystemdNetworkd - Debian Wiki](https://wiki.debian.org/SystemdNetworkd)

```
(root)# mv /etc/network/interfaces /etc/network/interfaces.old
```

## Dracut

Remeber we discussed about setting LUKS with a preset key file? This is the right time.
We use [dracut](https://wiki.archlinux.org/title/Dracut) to generate
[initramfs](https://wiki.archlinux.org/title/Arch_boot_process#initramfs) image,
and pack the
[key file](https://wiki.archlinux.org/title/Dm-crypt/Device_encryption#Types_of_keyfiles)
into it. The reason I choose dracut instead of mkinitcpio is that mkinitcpio is
Arch-specific, since I always try to avoid using tools limited to specific distros.

[Add key file](https://wiki.archlinux.org/title/Dm-crypt/Device_encryption#Adding_LUKS_keys)
to encrypted partition.

```
cryptsetup luksAddKey /dev/disk/by-partlabel/ROOTPART /etc/cryptsetup-keys.d/root.key
```

Create `/etc/dracut.conf.d/dracut.conf`.

```
enhanced_cpio="yes"
compress="cat"
do_strip="no"
install_optional_items+=" /etc/cryptsetup-keys.d/root.key "
```

By default, dracut will be triggered automatically after kernel update, for Arch
it's done by [pacman hooks](https://wiki.archlinux.org/title/Pacman#Hooks)
, for Fedora and Debian it's done by systemd
[kernel-install(8)](https://man.archlinux.org/man/kernel-install.8), they conform
different name conventions and install images into different locations. To uniform
their behaviors, we disable their default actions and replace with our own.

Since we want to install boot images into `/efi/linux/`, we first create our own
dracut install script, put it into say `/usr/local/bin/dracut-install.sh`:

```
#!/bin/bash

set -e

KVER="$1"
DEST=/boot

KDIR=/usr/lib/modules
[[ -n "$KVER" ]] || KVER=$(ls -1 $KDIR | tail -n 1)
KIMG=${KDIR}/${KVER}/vmlinuz # fedora, archlinux
[[ -f $KIMG ]] || KIMG=/boot/vmlinuz-${KVER} # ubuntu
[[ -f $KIMG ]] || exit 1

echo "==> generating initramfs.img ..."
dracut --force --hostonly --no-hostonly-cmdline \
    --kver "$KVER" "${DEST}/initramfs.img"
echo "==> installed '${DEST}/initramfs.img' (${KVER})"
install -Dm0644 $KIMG ${DEST}/vmlinuz
echo "==> installed '${DEST}/vmlinuz' (${KVER})"

install -Dm0644 ${DEST}/initramfs.img /efi/linux/initramfs.img
echo "==> installed '/efi/linux/initramfs.img' (${KVER})"
install -Dm0644 ${DEST}/vmlinuz /efi/linux/vmlinuz
echo "==> installed '/efi/linux/vmlinuz' (${KVER})"
```

Then we run it once manually to initialize boot images.

Next, we modify the pacman hook for Arch and the kernel-install plugin for Fedora
and Debian to let them trigger our script.

For Arch pacman hook, create `/etc/pacman.d/hooks/90-dracut-install.hook`:

```
[Trigger]
Type = Path
Operation = Install
Operation = Upgrade
Operation = Remove
Target = usr/lib/dracut/*
Target = usr/lib/firmware/*
Target = usr/src/*/dkms.conf
Target = usr/lib/systemd/systemd
Target = usr/bin/cryptsetup
Target = usr/bin/lvm

[Trigger]
Type = Path
Operation = Install
Operation = Upgrade
Target = usr/lib/modules/*/vmlinuz
Target = usr/lib/modules/*/pkgbase

[Trigger]
Type = Package
Operation = Install
Operation = Upgrade
Target = dracut

[Action]
Description = Updating initramfs with dracut
When = PostTransaction
Exec = /etc/pacman.d/scripts/dracut-install-alpm.sh
NeedsTargets
```

Then create `/etc/pacman.d/scripts/dracut-install-alpm.sh`:

```
#!/bin/bash

# If KERNEL_INSTALL_INITRD_GENERATOR is set, disable this hook
if [ -n "$KERNEL_INSTALL_INITRD_GENERATOR" ]; then
    exit 0
fi

while read -r line; do
    if [[ "$line" == 'usr/lib/modules/'+([^/])'/pkgbase' ]]; then
        read -r pkgbase < "/${line}"
        kver="${line#'usr/lib/modules/'}"
        kver="${kver%'/pkgbase'}"

        echo "--> Building initramfs for ${pkgbase} (${kver})"
        /usr/local/bin/dracut-install.sh "${kver}"
    fi
done
```

For Fedora and Debian kernel-install plugin, create
`/etc/kernel/install.d/50-dracut.install`:

```
#!/bin/bash

[[ $# == 4 ]] || exit 0

cmd="$1"
kver="$2"
dest="$3"
kimg="$4"

[[ "$cmd" == "add" ]] || exit 0
[[ -f "$kimg" ]] || exit 1

/usr/local/bin/dracut-install.sh "$kver"
```

## Limine

Now we setup bootlader using
[Limine](https://github.com/Limine-Bootloader/Limine).

Download `limine-binary` tarball from the
[latest release](https://github.com/Limine-Bootloader/Limine/releases/latest),
extract `BOOTX64.EFI` to `/efi/EFI/BOOT/BOOTX64.EFI`.

Create bootloader entrie `/efi/limine/limine.conf`:

```
timeout 0.25
quiet: yes

/Linux
   protocol: linux
   kernel_path: boot():/linux/vmlinuz
   module_path: boot():/linux/initramfs.img
   cmdline: rootflags=subvol=@ quiet splash
```

`/linux/vmlinuz` is actually pointed to `/efi/linux/vmlinuz`, since the path
is relative to the root of your
[EFI system partition](https://wiki.archlinux.org/title/EFI_system_partition)
, which is `/efi` in this guide. We will put kernel image and initramfs image
into `/efi/linux/` via dracut configuation in the next section.

To use
[BTRFS subvolume as root](https://wiki.archlinux.org/title/Btrfs#Mounting_subvolume_as_root)
mountpoint, use kernel parameter `rootflags=subvol=@`,
or you would get an error "Failed to start Switch Root" when booting up.

Note: If disk partitions were not following the
[Discoverable Partitions Specification](https://uapi-group.org/specifications/specs/discoverable_partitions_specification/)
, which means root partition would not be discovered and auto mounted,
booting system would stuck at
`a start job is running for /dev/gpt-auto-root` and timeout.
To fix this,
[name root partition in kernel parameters](https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#Configuring_the_boot_loader)
using [rd.luks.name](https://wiki.archlinux.org/title/Dm-crypt/System_configuration#rd.luks.name).

```
cmdline: rd.luks.name=<UUID>=root root=/dev/mapper/root rootflags=subvol=@
```

For Fedora and Debian there's one more step, by default they will trigger a
systemd [kernel-install(8)](https://man.archlinux.org/man/kernel-install.8)
plugin to generate systemd-boot loader entry automatically, we just disable it
since we've already created manually:

```
(root)# ln -s /dev/null /etc/kernel/install.d/90-loaderentry.install
```

Ref: [Limine - Arch Wiki](https://wiki.archlinux.org/title/Limine)

## Reboot

All done. Now reboot into the new system.
