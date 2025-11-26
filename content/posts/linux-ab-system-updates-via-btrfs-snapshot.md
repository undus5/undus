+++
title       = 'Linux A/B System Updates via BTRFS Snapshot'
date        = '2025-11-05'
lastmod     = '2025-11-26'
tags        = []
showSummary = true
showTOC     = true
weight      = 1000
+++

Inspired from Android A/B system updates mechanism.

<!--more-->

## Background

Things started when I was intrigued by some discussions about booting from
[BTRFS snapshots](https://wiki.archlinux.org/title/Btrfs#Snapshots)
directly. And before this A/B solution coming to my mind,
I was just using following basic commands to create and remove snapshots manually.

```
# btrfs subvolume snapshot / <destination>
# btrfs subvolume delete <destination>
```

## Principle

The core idea of this A/B solutions is, there are 2 subvolumes for root partition,
`@a` and `@b`, they are mutually to be the snapshot of each other.
And we maintain 2 bootloader entries for them respectively.
The tricky part is you need to alter the `fstab` to make
these 2 subvolumes point to the right ones after generating the new snapshot
everytime.

## Subvolumes

Let's begin with subvolume overview. You need entrering a live system environment
to create subvolumes.

```
# mount /dev/disk/by-partlabel/ROOTPART /mnt
# btrfs subvolume create /mnt/@a
# btrfs subvolume create /mnt/@a/@
# btrfs subvolume create /mnt/@b
# btrfs subvolume create /mnt/@b/@
# btrfs subvolume create /mnt/@home
```

If you feel strange about this `ROOTPART` label, you may read the basic
system installation article first:
[Bootstrap Install Any Linux Distro](/posts/bootstrap-install-any-linux-distro/).
For simplicity, the root partition in this guide is not encrypted, which means
LUKS is not involved.

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

This A/B solution can work with any bootloader, I use systemd-boot for now.

Systemd-boot entry for `@a` in `/efi/loader/entries/boota.conf`:

```
title Boot A
linux /boota/vmlinuz-linux
initrd /boota/initramfs-linux.img
options rootflags=subvol=@a/@ quiet
sort-key A
```

Systemd-boot entry for `@b` in `/efi/loader/entries/bootb.conf`:

```
title Boot B
linux /bootb/vmlinuz-linux
initrd /bootb/initramfs-linux.img
options rootflags=subvol=@b/@ quiet
sort-key B
```

If your system installation is followed my article 
[Bootstrap Install Any Linux Distro](/posts/bootstrap-install-any-linux-distro/),
you should also distinguish the `/etc/systemd/system/efistub-update.service`:

EFIstub update service for `@a/@`:

```
[Unit]
Description=Copy EFISTUB Kernel to EFI system partition
[Service]
Type=oneshot
ExecStart=/usr/bin/cp -af /boot/vmlinuz-linux /efi/boota/
ExecStart=/usr/bin/cp -af /boot/initramfs-linux.img /efi/boota/
```

EFIstub update service for `@b/@`:

```
[Unit]
Description=Copy EFISTUB Kernel to EFI system partition
[Service]
Type=oneshot
ExecStart=/usr/bin/cp -af /boot/vmlinuz-linux /efi/bootb/
ExecStart=/usr/bin/cp -af /boot/initramfs-linux.img /efi/bootb/
```

## Bash Script

All the processes can be automated into a bash script:

```bash
#!/usr/bin/bash
set -e

eprintf() {
    printf "${@}"
    exit 1
}

[[ ${EUID} == 0 ]] || eprintf "need root priviledge\n"

case ${1} in
    ab)
        _srcname=a
        _dstname=b
        ;;
    ba)
        _srcname=b
        _dstname=a
        ;;
    *)
        eprintf "Usage: $(basename ${0}) <ab|ba>\n"
        ;;
esac

_dstvol_alert="Warning: you are running under \`${_dstname}\` subvolume now\n"
findmnt /${_srcname} &>/dev/null && eprintf "${_dstvol_alert}"
findmnt /${_dstname} &>/dev/null || eprintf "${_dstvol_alert}"

printf "==> Copying kernel and initramfs from \`${_srcname}\` to \`${_dstname}\` ... "
_stubsrc=/efi/boot${_srcname}
_stubdst=/efi/boot${_dstname}
_stubtmp=/efi/boott
[[ -d ${_stubdst} ]] && mv ${_stubdst} ${_stubtmp}
[[ -d ${_stubsrc} ]] && cp -r ${_stubsrc} ${_stubdst}
[[ -d ${_stubtmp} ]] && rm -rf ${_stubtmp}
printf " Done\n"

_dstvol=/${_dstname}/@

# this step makes the snapshot writable in case it is readonly
[[ -d ${_dstvol} ]] && btrfs prop set -f -ts ${_dstvol} ro false

printf "==> Cleaning \`${_dstname}\` snapshot ... "
[[ -d ${_dstvol} ]] && btrfs subvolume delete ${_dstvol}
printf " Done\n"

printf "==> Creating snapshot from \`${_srcname}\` to \`${_dstname}\` ... \n"
btrfs subvolume snapshot / ${_dstvol}

printf "==> Tweaking \`${_dstname}\` fstab ... "
sed -i -r \
    -e "s#/${_dstname}#/${_srcname}#" \
    -e "s#@${_dstname}\s+0#@${_srcname}   0#" \
    -e "s#@${_srcname}/@#@${_dstname}/@#" \
    ${_dstvol}/etc/fstab
printf " Done\n"

printf "==> Tweaking \`${_dstname}\` efistub-update.service ... "
sed -i "s/boot${_srcname}/boot${_dstname}/" \
    ${_dstvol}/etc/systemd/system/efistub-update.service
printf " Done\n"

printf "==> Updating timestamp ... \n"
rm /${_dstname}/*.txt
_time=$(date +%Y%m%d.%H%M%S)
_timetxt=/${_dstname}/timestamp.${_time}.txt
printf "${_time}\n" > ${_timetxt}
printf "Saved ${_timetxt}\n"
```

## Trivial

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

[apt](https://man.archlinux.org/man/apt-get.8.en):
`apt autoremove && apt autoclean`

[dnf](https://man.archlinux.org/man/dnf5-clean.8.en):
`dnf clean packages`
