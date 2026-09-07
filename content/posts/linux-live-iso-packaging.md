+++
title       = 'Linux Live ISO Packaging'
lastmod     = '2026-09-07'
date        = '2026-06-20'
tags        = ['Linux']
showSummary = true
showTOC     = true
weight      = 1000
draft       = false
hidden      = false
+++

The last piece of puzzle.

<!--more-->

## Series Index

1. [Linux Bootstrap Installation](/posts/linux-bootstrap-installation/)
2. [Linux A/B System Updates via BTRFS Snapshot](/posts/linux-ab-system-updates-via-btrfs-snapshot/)
3. [Linux Post Installation](/posts/linux-post-installtion/)
4. [Linux Desktop: Sway, Labwc, GUI Apps](/posts/linux-desktop-sway-labwc-gui-apps/)
5. Linux Live ISO Packaging

## Preface

After [Linux Bootstrap Installation](/posts/linux-bootstrap-installation/),
we can package our own live ISO from that root filesystem, using `dracut`,
`squashfs-tools`, `limine` and `xorriso`.

## Structure

Let's say our ISO filesystem is under `/mnt/isofs`, the directory structure
would look like this:

```
/mnt/isofs
  |-- boot
     --- initramsfs-live.img
     --- vmlinuz
  |-- live
     --- squashfs.img
  |-- limine
     --- limine.conf
     --- limine-bios.sys
     --- limine-bios-cd.bin
     --- limine-bios-uefi.bin
  |-- EFI
     |-- BOOT
        --- BOOTX64.EFI
```

`|--` represents folder, `---` represents file.

We will create and install them one by one.

## Initramfs

Before the actual ISO building, there's one more step to do in the rootfs,
which is generating initramsfs image dedicated for live os via dracut and it's
`dmsquash-live` module.

Let's say our rootfs is under `/mnt/rootfs`, first we need to mount necessary
virtual filesystems to it:

```
(root)# mount --mkdir --types proc /proc /mnt/rootfs/proc
(root)# mount --mkdir --rbind --make-rslave /dev /mnt/rootfs/dev
(root)# mount --mkdir --rbind --make-rslave /run /mnt/rootfs/run
(root)# mount --mkdir --rbind --make-rslave /sys /mnt/rootfs/sys
```

Then chroot into the rootfs:

```
(root)# chroot /mnt/rootfs
```

Get kernel version:

```
(chroot)# KVER=$(ls -1 /usr/lib/modules | tail -n 1)
```

Generate initrams image:

```
(chroot)# dracut --force --no-hostonly --add "dmsquash-live" \
   --kver "$KVER" /boot/initramfs-live.img
```

`--no-hostonly` option is required, since `dmsquash-live` isn't a hostonly
module, without the option you would encounter error like
"dracut module cannot be installed".

Exit chroot and unmount virtual filesystems:

```
(chroot)# exit
(root)# umount -R /mnt/rootfs/proc
(root)# umount -R /mnt/rootfs/dev
(root)# umount -R /mnt/rootfs/run
(root)# umount -R /mnt/rootfs/sys
```

Then we copy the generated initramfs image and kernel image to iso filesystem:

```
(root)# mkdir -p /mnt/isofs/boot
(root)# cp /mnt/rootfs/boot/initramfs-live.img /mnt/isofs/boot/
(root)# cp /mnt/rootfs/boot/vmlinuz /mnt/isofs/boot/
```

## SquashFS

Then we package the rootfs into a SquashFS image:

```
(root)# mkdir -p /mnt/isofs/LiveOS
(root)# mksquashfs /mnt/rootfs /mnt/isofs/live/squashfs.img -comp zstd -no-xattrs -quiet
```

Require `squashfs-tools` package installed.

Ref: [mksquashfs(1)](https://man.archlinux.org/man/mksquashfs.1)

## Limine

Next we download `limine-binary.tar.xz` from
[limine releases](https://github.com/Limine-Bootloader/Limine/releases)
, extract and install needed files into iso filesystem:

```
(root)# mkdir -p /mnt/isofs/limine
(root)# tar xf limine-binary.tar.xz
(root)# cp limine-binary/limine-bios.sys /mnt/isofs/limine/
(root)# cp limine-binary/limine-bios-cd.bin /mnt/isofs/limine/
(root)# cp limine-binary/limine-bios-uefi.bin /mnt/isofs/limine/
```

Create `/mnt/isofs/limine/limine.conf` with:

```
/My Live Linux
   protocol: linux
   kernel_path: boot():/boot/vmlinuz
   module_path: boot():/boot/initramfs-live.img
   cmdline: root=live:LABEL=MY_LIVE_LINUX rd.live.dir=/live rd.live.ram=1
```

`LABEL=` could be arbitrary name.\
`rd.live.dir=/live` defines where to put squashfs image, it has a default value
which is "/LiveOS", here I made some customization.\
`rd.live.ram=1` let the live system fully running in the RAM, which means you
can eject the USB drive after booting up.

Ref: [dracut.cmdline(7)](https://dracut-ng.github.io/dracut/man/dracut.cmdline.7.html)
, [Limine README](https://github.com/Limine-Bootloader/Limine)

## ISO

Now we can package our ISO image with `xorriso`.

```
(root)# LABEL=MY_LIVE_LINUX
(root)# xorriso -as mkisofs -R -r -J -V $LABEL \
           -b limine/limine-bios-cd.bin \
           -no-emul-boot -boot-load-size 4 -boot-info-table \
           --efi-boot limine/limine-uefi-cd.bin \
           -efi-boot-part --efi-boot-image \
           -o /mnt/my-live-linux.iso \
           /mnt/isofs
```

Ref: [xorrisofs(1)](https://man.archlinux.org/man/xorrisofs.1.en)

Right now it only works under UEFI, there's one more step to make it support
legacy BIOS.

Download `limine-x.y.z.tar.xz` from
[limine releases](https://github.com/Limine-Bootloader/Limine/releases)
, then extract and compile it:

```
(root)# tar xf limine-x.y.z.tar.xz
(root)# cd limine-x.y.z
(root)# ./configure --enable-bios-cd
(root)# make
(root)# limine bios-install /mnt/my-live-linux.iso
```

Dependencies required for compilation: `clang`, `lld`, `llvm`, `nasm`.

All done.

## Troubleshooting

If your encounter error message like
"dracut fatal: don't know how to handle root=live:label" when booting your
created ISO, you are missing "dmsquash-live" module. For example, on Fedora,
you need to make sure `dracut-live` package being installed.
