+++
title       = 'Linux Bootstrap Installation'
aliases     = ["/posts/bootstrap-install-any-linux-distro/"]
date        = '2025-10-19'
lastmod     = '2025-11-04'
tags        = []
showTOC     = true
showSummary = true
weight      = 1000
+++

Distro is trival, just learn the basics and build your own.

<!--more-->

## Series Index

1. Linux Bootstrap Installation
2. [Linux A/B System Updates via BTRFS Snapshot](/posts/linux-ab-system-updates-via-btrfs-snapshot/)
3. [Linux Post Installation: Desktop Preparation](/posts/linux-post-installtion-desktop-preparation/)
4. [Linux Desktop: Sway, Labwc, GUI Apps](/posts/linux-desktop-sway-labwc-gui-apps/)

## Preface

Want to stop distro hopping? Sure, just go read through the
[ArchWiki](https://wiki.archlinux.org/title/Main_page). Don't get me wrong,
I'm not selling Arch Linux to you, just the wiki. The reason you always be 
distracted by shining fancy components from some new releases
or emerging distros, is that you don't have a big picture about linux and
its ecosystem, and you haven't figure out what do you really need.
This is the most thing I learned after reading through the wiki.
When I finished reading, I learned what choices are there, and found my needs,
then built my own configurations.

In fact, you can install nearly all the linux distros manually in a similar way,
aka "the arch way", since the installers they offered are doing the same job
under the hood, but with less flexibility and more bloat. So if you want to
settle down, go read the wiki, learn the basics, then you can pick up whatever
distros you like and tweaking them to the shape you want, the only differences
are just package management system, release model and community support.

This guide is based on Arch Linux, but also works for Debian/Ubutnu and Fedora,
the differences are minor, demonstrated in [Debian Fedora](#debian-fedora) section.
I always avoid using distro specific tools as much as I can, such as mkinitcpio,
pacman hooks, etc.

## Live ISO

You need a [live iso](https://archlinux.org/download/)
image to boot into live system for doing installation. 

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
a typical practice is 1MiB. In our example, we assigned 1GB to the EFI partition,
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
(root)# btrfs subvolume create /mnt/@data
(root)# umount /mnt

(root)# mount -o subvol=@ /dev/mapper/root /mnt
(root)# mount -o subvol=@home --mkdir /dev/mapper/root /mnt/home
(root)# mount -o subvol=@data --mkdir /dev/mapper/root /mnt/data
(root)# mount --mkdir /dev/disk/by-partlabel/EFIPART /mnt/efi
```

Another great BTRFS feature is it's easy to create snapshots by its
Copy on Write (CoW) nature, useful for creating backup against system crash.

## WiFi

Use [iwd](https://wiki.archlinux.org/title/Iwd) to connect to WiFi.

## Repo Mirror

Check the [mirrorlist](https://archlinux.org/mirrorlist/) from official website,
then edit `/etc/pacman.d/mirrorlist`.

> For Debian/Ubuntu and Fedora, refer to [Debian Fedora](#debian-fedora) section.

## Base System

Now we are ready to install the base system. We will use a dedicated tool
to install base system packages into /mnt.

For Arch it's
[Pacstrap](https://wiki.archlinux.org/title/Installation_guide#Install_essential_packages):

```
(root)# pacstrap -K /mnt \
    base linux linux-firmware btrfs-progs dracut zram-generator neovim iwd
```

Also install `amd-ucode` or `intel-ucode` for CPU microcode updates.

> For Debian/Ubuntu and Fedora, refer to [Debian Fedora](#debian-fedora) section.

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
UUID=xxxxxxxx-...-xxxxxxxxxxxx /data btrfs compress=zstd,subvol=/@data 0 0
UUID=XXXX-XXXX /efi vfat defaults 0 0
```

## Chroot

Mount virtual filesystems to `/mnt` then chroot into it :

```
(root)# for dir in dev proc run sys; do mount --rbind --make-rslave /$dir /mnt/$dir; done
(root)# chroot /mnt /bin/bash
```

## Timezone

```
(root)# ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
```

## Localization

```
(root)# echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
(root)# echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen
(root)# locale-gen
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

## Systemd-Networkd

In my experience,
[systemd-networkd](https://wiki.archlinux.org/title/Systemd-networkd)
is better than NetworkManager especially for maintaining bridged network
interfaces for virtual machines.

Run `ip link show` command to get your network interface names,
for example: enp0s1, wlan0.

For wired network interface, create `/etc/systemd/network/23-lan.network`.

```
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
```

For wireless network interface, create `/etc/systemd/network/25-wlan.network`.

```
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
```

Setting unique `RouteMetric` for different network interfaces is necessary,
or they will enter into "race condition", which will cause extreamly slow network
connections.

`RequiredForOnline=routable` is necessary to prevent
`systemd-networkd-wait-online.service` hanging the systemd boot process.

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
(root)# systemctl enable systemd-resolved.service
```

## Zram

We have lage memory storage nowadays, so just put the swap into RAM using
[zram](https://wiki.archlinux.org/title/Zram).

Create `/etc/systemd/zram-generator.conf`, the size is in MiB.

```
[zram0]
zram-size = min(ram, 8192)
compression-algorithm = zstd
```

## Dracut

Remeber I mentioned setting LUKS with a preset key file? This is the right time.
We use [dracut](https://wiki.archlinux.org/title/Dracut) to generate
[initramfs](https://wiki.archlinux.org/title/Arch_boot_process#initramfs) image,
and pack the
[key file](https://wiki.archlinux.org/title/Dm-crypt/Device_encryption#Types_of_keyfiles)
into it.

[Apply key file](https://wiki.archlinux.org/title/Dm-crypt/Device_encryption#Adding_LUKS_keys)
to encrypted partition.

```
cryptsetup luksAddKey /dev/disk/by-partlabel/ROOTPART /etc/cryptsetup-keys.d/root.key
```

Create `/etc/dracut.conf.d/dracut.conf`.

```
hostonly="yes"
enhanced_cpio="yes"
compress="cat"
do_strip="no"
install_optional_items+=" /etc/cryptsetup-keys.d/root.key "
```

## Systemd-Boot

[Install UEFI boot manager](https://wiki.archlinux.org/title/Systemd-boot#Installing_the_UEFI_boot_manager).

```
bootctl install
systemctl enable systemd-boot-update.service
```

> Note: Debian/Ubuntu and Fedora need some extra work to continue, refer to
> [Debian Fedora](#debian-fedora) section then jump back.

Since the kernel and initramfs image will be installed to `/boot/` by default,
we need to copy them to our
[EFI system partition](https://wiki.archlinux.org/title/EFI_system_partition#Alternative_mount_points)
manually and create
[systemd hooks](https://wiki.archlinux.org/title/EFI_system_partition#Using_systemd)
to update them automatically.

```
(root)# mkdir -p /efi/boota
(root)# cp -a /boot/vmlinuz-linux /efi/boota/
(root)# cp -a /boot/initramfs-linux.img /efi/boota/
```

Create `/etc/systemd/system/efistub-update.path`.

```
[Unit]
Description=Copy EFISTUB Kernel to EFI system partition
[Path]
PathChanged=/boot/initramfs-linux.img
[Install]
WantedBy=multi-user.target
WantedBy=system-update.target
```

Create `/etc/systemd/system/efistub-update.service`.

```
[Unit]
Description=Copy EFISTUB Kernel to EFI system partition
[Service]
Type=oneshot
ExecStart=/usr/bin/cp -af /boot/vmlinuz-linux /efi/boota/
ExecStart=/usr/bin/cp -af /boot/initramfs-linux.img /efi/boota/
```

Enable the units.

```
(root)# systemctl enable efistub-update.{path,service}
```

Create bootloader entry `/efi/loader/entries/boota.conf`.

```
title Arch Linux
linux /boota/vmlinuz-linux
initrd /boota/initramfs-linux.img
options rootflags=subvol=@ quiet splash
```

To use
[BTRFS subvolume as root](https://wiki.archlinux.org/title/Btrfs#Mounting_subvolume_as_root)
mountpoint, use kernel parameter `rootflags=subvol=@`,
or you would get an error "Failed to start Switch Root" when booting up.

Edit `/efi/loader/loader.conf`.

```
default boota.conf
timeout 0
editor no
```

`timeout 0` means the boot menu will not be displayed by default,
and the system will immediately boot into the default entry.
To reveal the boot menu in this scenario, a key needs to be pressed and
held down during the boot process, before systemd-boot initializes.
The recommended key for this action is the space bar.
Other keys may also work, but space bar is widely suggested.

Note: If disk partitions were not following the
[Discoverable Partitions Specification](https://uapi-group.org/specifications/specs/discoverable_partitions_specification/)
, which means root partition would not be discovered and auto mounted,
booting system would stuck at
`a start job is running for /dev/gpt-auto-root` and timeout.
To fix this,
[name root partition in kernel parameters](https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#Configuring_the_boot_loader)
using [rd.luks.name](https://wiki.archlinux.org/title/Dm-crypt/System_configuration#rd.luks.name).

```
options rd.luks.name=<UUID>=root root=/dev/mapper/root rootflags=subvol=@
```

## Debian Fedora

<-> [Live ISO](#live-iso)

[Debian](https://www.debian.org/),
[Ubuntu](https://ubuntu.com/download),
[Fedora](https://www.fedoraproject.org/)

<-> [Repo Mirror](#repo-mirror)

Debian: Check [Debian Mirrors (worldwide)](https://www.debian.org/mirror/list),
then edit `/etc/apt/sources.list`.

Ubuntu: Check [Mirrors : Ubuntu](https://launchpad.net/ubuntu/+archivemirrors)
then edit `/etc/apt/sources.list`.

Fedora: Check [MirrorManager](https://mirrormanager.fedoraproject.org),
then edit `/etc/yum.repos.d/fedora.repo`.

<-> [Base System](#base-system)

Debian/Ubuntu:
[Debootstrap](https://wiki.debian.org/Debootstrap):

```
(root)# debootstrap --include=\
    linux-image-amd64,non-free-firmware,btrfs-progs,dracut,\
    systemd-zram-generator,systemd-boot,neovim,iwd \
    stable /mnt http://deb.debian.org/debian/
```

The Repo URL for Ubuntu is http://archive.ubuntu.com/ubuntu/

Fedora: DNF:

```
(root)# dnf --use-host-config --releasever=43 --installroot=/mnt group install core
(root)# dnf --use-host-config --releasever=43 --installroot=/mnt install \
    kernel linux-firmware btrfs-progs dracut zram-generator systemd-boot neovim iwd
```

Microcode packages:

Fedora: AMD `amd-ucode-firmware`, Intel `microcode_ctl`\
Debian: AMD `amd64-microcode`, Intel `intel-microcode`

<-> [Systemd-Boot](#systemd-boot)

Unlike Arch Linux, Debian and Fedora will trigger systemd's
[kernel-install(8)](https://man.archlinux.org/man/kernel-install.8)
to copy initramfs and kernel images to ESP partition and generate boot entry
automatically when using dracut and systemd-boot. Since we want to maintain
this process in our own way for the flexibility, we need to disable their
kernel-install plugins and write our own.

```
(root)# ln -s /dev/null /etc/kernel/install.d/50-dracut.install
(root)# ln -s /dev/null /etc/kernel/install.d/90-loaderentry.install
```

Create `/etc/kernel/install.d/60-bootstub.install`, make it executable.

```
#!/bin/bash
set -e
[[ ${#} == 4 ]] || exit 0
_command="${1}"
_kernel_verion="${2}"
_dest_dir="/boot"
_kernel_image="${4}"
[[ "${_command}" == "add" ]] || exit 0
[[ -f "${_kernel_image}" ]] || exit 1
cp -f "${_kernel_image}" "${_dest_dir}/vmlinuz-linux"
dracut -f \
    --kver "${_kernel_verion}" \
    --kernel-image "${_kernel_image}" \
    "${_dest_dir}/initramfs-linux.img"
chmod 600 "${_dest_dir}/initramfs-linux.img"
```

<-> [Systemd-Networkd](#systemd-networkd)

For Debian you need to move out `/etc/network/interfaces` according to
[SystemdNetworkd - Debian Wiki](https://wiki.debian.org/SystemdNetworkd)

```
(root)# mv /etc/network/interfaces /etc/network/interfaces.old
```

## Reboot
