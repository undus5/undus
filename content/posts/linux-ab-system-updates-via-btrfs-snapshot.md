+++
title       = 'Linux A/B System Updates via BTRFS Snapshot'
lastmod     = '2026-01-30'
date        = '2025-11-05'
tags        = ['linux']
showSummary = true
showTOC     = true
weight      = 1000
+++

Inspired from Android A/B system updates mechanism.

<!--more-->

## Series Index

1. [Linux Bootstrap Installation](/posts/linux-bootstrap-installation/)
2. Linux A/B System Updates via BTRFS Snapshot
3. [Linux Post Installation](/posts/linux-post-installtion/)
4. [Linux Desktop: Sway, Labwc, GUI Apps](/posts/linux-desktop-sway-labwc-gui-apps/)
5. [Linux Live ISO Packaging](/posts/linux-live-iso-packaging/)

## Preface

This guide is distro independent, could work on any distros.

## Background

Things started when I was intrigued by some discussions about booting from
[BTRFS snapshots](https://wiki.archlinux.org/title/Btrfs#Snapshots)
directly. And before this A/B solution coming to my mind,
I was just using following commands to create and remove snapshots manually.

```
(root)# btrfs subvolume snapshot / <destination>
(root)# btrfs subvolume delete <destination>
```

## Principle

The core idea of this A/B solutions is there are two subvolumes for root partition,
`@a` and `@b`, they are mutually to be the snapshot of each other.
And we maintain two bootloader entries for them respectively.
The tricky part is you need to alter the `fstab` to make
these two subvolumes point to the right ones after generating the new snapshot
everytime.

## Subvolumes

Let's begin with subvolume overview. You need entrering a live system environment
to create subvolumes.

```
(root)# mount /dev/disk/by-partlabel/ROOTPART /mnt
(root)# btrfs subvolume create /mnt/@a
(root)# btrfs subvolume create /mnt/@a/@
(root)# btrfs subvolume create /mnt/@b
(root)# btrfs subvolume create /mnt/@b/@
(root)# btrfs subvolume create /mnt/@home
```

If you feel strange about this `ROOTPART` label, read the previous guide for
basic system installation first. For simplicity, the root partition in this guide
is not encrypted, which means LUKS is not involved.

The nested subvolumes `@` are the real root partition, which will be mounted as
`/`, and they also are the snapshots for each other
(subvolume and snapshot are basically same in BTRFS). The reason of subvolume
stucture be like this is when we creating BTRFS snapshot, the destination path
must not exist, which means we need to delete old `@` subvolume first to create
new one.

For example, if we remove this nested layer, just mount `@a` as `/`,
`@b` as `/b`, we could not remove `/b` or `@b` since it's a mount point in use.
If we add this nested layer, mount `@a/@` as `/` and still `@b` as `/b`,
we could delete and recreate `/b/@` from `@a` to `@b` and vice versa.

## Fstab

Fstab for `@a/@`:

```
# <file system> <dir> <type> <options> <dump> <pass>
UUID=40379083-xxxx-xxxx-xxxx-848931c8d87c /     btrfs compress=zstd,subvol=/@a/@ 0 0
UUID=40379083-xxxx-xxxx-xxxx-848931c8d87c /b    btrfs compress=zstd,subvol=/@b   0 0
UUID=40379083-xxxx-xxxx-xxxx-848931c8d87c /home btrfs compress=zstd,subvol=/@home 0 0
UUID=3A19-XXXX /efi vfat defaults 0 2
```

Fstab for `@b/@`:

```
# <file system> <dir> <type> <options> <dump> <pass>
UUID=40379083-xxxx-xxxx-xxxx-848931c8d87c /     btrfs compress=zstd,subvol=/@b/@ 0 0
UUID=40379083-xxxx-xxxx-xxxx-848931c8d87c /a    btrfs compress=zstd,subvol=/@a   0 0
UUID=40379083-xxxx-xxxx-xxxx-848931c8d87c /home btrfs compress=zstd,subvol=/@home 0 0
UUID=3A19-XXXX /efi vfat defaults 0 2
```

Be careful with the minor differences.

## Bootloader Entries

This A/B solution can work with any bootloader, here's an example of
[Limine](https://github.com/Limine-Bootloader/Limine).

Edit `/efi/limine/limine.conf`:

```
timeout 0.25
quiet: yes

/Boot A
   protocol: linux
   kernel_path: boot():/a/vmlinuz
   module_path: boot():/a/initramfs.img
   cmdline: rootflags=subvol=@a/@ quiet splash

/Boot B
   protocol: linux
   kernel_path: boot():/b/vmlinuz
   module_path: boot():/b/initramfs.img
   cmdline: rootflags=subvol=@b/@ quiet splash
```

## Bash Script

All the processes can be automated into a bash script:

```
#!/usr/bin/bash

set -e

errf() { printf "$@\n" >&2; exit 1; }

(( EUID == 0 )) || errf "need root priviledge"

case "$1" in
    ab)
        srcname=a
        dstname=b
        ;;
    ba)
        srcname=b
        dstname=a
        ;;
    *)
        errf "Usage: $(basename $0) <ab|ba>"
        ;;
esac

srcvol=/${srcname}/@
dstvol=/${dstname}/@

dstvol_alert="==> abort: you are running under '@${dstvol}' subvolume now"
findmnt /${srcname} &>/dev/null && errf "$dstvol_alert"
findmnt /${dstname} &>/dev/null || errf "$dstvol_alert"

stubsrc=/efi/${srcname}
stubdst=/efi/${dstname}
mkdir -p $stubdst
cp -rfP ${stubsrc}/* ${stubdst}/
echo "==> copied vmlinuz, initramfs.img from '@${srcname}' to '@${dstname}'"

# remove the read-only protection just in case
btrfs prop set -f -ts $dstvol ro false

btrfs subvolume delete $dstvol > /dev/null
echo "==> deleted subvolume '${dstvol}'"

btrfs subvolume snapshot / $dstvol > /dev/null
echo "==> created snapshot of '${srcvol}' in '${dstvol}'"

echo "==> updated fstab in '/${dstname}/@'"
sed -i -r \
    -e "s#/${dstname}#/${srcname}#" \
    -e "s#@${dstname}\s+0#@${srcname}   0#" \
    -e "s#@${srcname}/@#@${dstname}/@#" \
    ${dstvol}/etc/fstab

time=$(date +%Y%m%d.%H%M%S)
timetxt=/${dstname}/timestamp.${time}.txt
rm /${dstname}/*.txt
echo "${time}" > $timetxt
echo "==> created ${timetxt}"
```

## Cache Clean

You may want to clean cache files before creating snapshot to save storage.

[Limit systemd journal size](https://wiki.archlinux.org/title/Systemd/Journal#Journal_size_limit)
in `/etc/systemd/journald.conf`:

```
[Journal]
SystemMaxUse=120M
```

Clean package cache:

[pacman](https://wiki.archlinux.org/title/Pacman#Cleaning_the_package_cache):
`paccache -r && paccache -ruk0`

[dnf-clean(8)](https://man.archlinux.org/man/dnf5-clean.8.en):
`dnf clean packages`

[apt(8)](https://man.archlinux.org/man/apt.8.en):
`apt autoremove && apt autoclean`
