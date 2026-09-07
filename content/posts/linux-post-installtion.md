+++
title       = 'Linux Post Installation'
subtitle    = ''
lastmod     = '2026-07-15'
date        = '2025-11-26'
tags        = ['linux']
showSummary = true
showTOC     = true
weight      = 1000
+++

Essential configurations before desktop components getting involved.

<!--more-->

## Series Index

1. [Linux Bootstrap Installation](/posts/linux-bootstrap-installation/)
2. [Linux A/B System Updates via BTRFS Snapshot](/posts/linux-ab-system-updates-via-btrfs-snapshot/)
3. Linux Post Installation
4. [Linux Desktop: Sway, Labwc, GUI Apps](/posts/linux-desktop-sway-labwc-gui-apps/)
5. [Linux Live ISO Packaging](/posts/linux-live-iso-packaging/)

## Preface

This guide is distro independent, tested on Arch and Fedora.

## Default Editor

```
(root)# echo "export EDITOR=/usr/bin/nvim" > /etc/profile.d/nvim-default-editor.sh
```

You could replace `nvim` with whatever you like.

## PipeWire

Install [PipeWire](https://wiki.archlinux.org/title/PipeWire) related packages:

Arch: `pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber`\
Fedora: `pipewire pipewire-utils`

## GPU Drivers

To choose [GPU](https://wiki.archlinux.org/title/Graphics_processing_unit) for
Linux, AMD is still the prefered option for stability and performance,
but for daily use, it doesn't matter. I've learned that Nvidia driver is getting
solid enough these days, and Intel is catching up too.

Install `mesa` and `vulkan` related packages:

Arch AMD, Intel: `mesa vulkan-radeon vulkan-intel intel-media-driver`\
Arch Nvidia: `nvidia-open` for GPU newer than GTX 1650

For Fedora, need to enable [RPM Fusion](https://rpmfusion.org/)
then install freeworld packages:

```
(root)# dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-{free,nonfree}-release-$(rpm -E %fedora).noarch.rpm 
# FFmpeg
(root)# dnf swap ffmpeg-free ffmpeg --allowerasing
# AMD GPU
(root)# dnf install mesa-va-drivers-freeworld
# Intel GPU
(root)# dnf install intel-media-driver
# Nvidia GPU newer than GTX 1650
(root)# dnf install akmod-nvidia
```

Ref: [Multimedia on Fedora](https://rpmfusion.org/Howto/Multimedia)
, [NVIDIA on Fedora](https://rpmfusion.org/Howto/NVIDIA)

Use [mpv](https://wiki.archlinux.org/title/Mpv#Hardware_video_acceleration)
to test
[hardware acceleration](https://wiki.archlinux.org/title/Hardware_video_acceleration)
, with command `mpv --hwdec=auto <videofile>`

## Bluetooth

Install [Bluetooth](https://wiki.archlinux.org/title/Bluetooth) related packages:

Arch: `bluez bluez-utils`\
Fedora: `bluez bluez-tools`

Enable systemd service: `systemctl enable --now bluetooth.service`.

## Printer

Install [CUPS](https://wiki.archlinux.org/title/CUPS) related packages:

Arch, Fedora: `cups cups-pdf`

Enable systemd service: `systemctl enable --now cups.service`.

The CUPS server can be fully administered through the web interface,
and there’s documentation for adding printer
[http://localhost:631/help/admin.html](http://localhost:631/help/admin.html).

## Non-root LUKS Disk

Here's how to add a second disk drive encrypted with LUKS. For initializing and
formating encrypted disk, refer to
[Linux Bootstrap Installation](/posts/linux-bootstrap-installation/).
Let's say the entrypted partition is `/dev/sda1`, the decrypted partition map
name is `hdd`, and you want to mount it at `/data`.

1, create keyfile (only follow this step if your root partition is encrypted):

```
(root)# printf '%s' 'your_passphrase' | install -m 0600 /dev/stdin /etc/cryptsetup-keys.d/hdd.key
```

2, get entrypted partition's UUID:

```
(root)# blkid -s UUID -o value /dev/sda1
```

3, create crypttab `/etc/crypttab` with:

```
hdd UUID=...sda1_uuid... /etc/cryptsetup-keys.d/hdd.key
```

4, open encrypted partition, get decrypted partition's UUID:

```
(root)# cryptsetup open /dev/sda1 hdd
(root)# blkid -s UUID -o value /dev/mapper/hdd
```

5, add decrypted partition mount point to `/etc/fstab`:

```
...
UUID=...hdd_uuid... /data btrfs compress=zstd 0 0
...
```

Ref: [Dm-crypt/Device_encryption#Keyfiles](https://wiki.archlinux.org/title/Dm-crypt/Device_encryption#Keyfiles)
, [Dm-crypt/System_configuration#crypttab](https://wiki.archlinux.org/title/Dm-crypt/System_configuration#crypttab)

## Plymouth

Plymouth provides themed graphical interface for entering LUKS passphrase
and boot animation.

Packages:\
Fedora: `plymouth-system-theme`\
Arch: `plymouth`

Themes are under `/usr/share/plymouth/themes/`, add to config file
`/etc/plymouth/plymouthd.conf`:

```
[Daemon]
Theme=spinner
```

Fix flickering on LUKS passphrase interface by disabling SimpleDRM. SimpleDRM
is for removing flickering between motherboard splash screen and plymouth, it
works great on normal configuration, but triggering another flickering when
using LUKS (black for a second), to disable it, append `plymouth.use-simpledrm=0`
to kernel parameters in your bootloader config file.

Ref: [Plymouth#Using_SimpleDRM](https://wiki.archlinux.org/title/Plymouth#Using_SimpleDRM)
