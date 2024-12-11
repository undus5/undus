+++
title       = "QEMU Install Windows 11 Guest"
lastmod     = 2024-12-11T10:12:00+08:00
date        = 2024-12-09
showSummary = true
showTOC     = true
weight      = 1000
+++

Get rid of complex middle layers.

<!--more-->

## Background

Virtual machine management tool like libvirt is overkill for personal use, I think,
from this perspective, it just increases the complexity and the cost for learning,
which are unnecessary.

However, using the low level tool directly is not easy.
Normally I would go to the official website reading the documentation when trying
to learn some new tools, but this approach is not working well on QEMU, it's
[documentation](https://www.qemu.org/documentation/) is not friendly for beginners,
there's no "Getting Started" or "Tutorial", I didn't know where to start.

[Arch wiki](https://wiki.archlinux.org/title/QEMU)
is way better, but feel not kinda specific, I'm lacking some knowledge about such as
operating system and hardware interface I think, so still being a bit confusing.
Google searching, no luck either, everyone is using libvirt.
Then I asked ChatGPT for help, just sent a simple phrase "qemu command for windows guest",
and it gave me a really well example with explaination, with the help of this
good start point, I went back to the arch wiki then made progress.

I barely use AI tools, since documentations and books are good enough for learning,
I always feel nothing about those AI hyping things from the internet,
but this time it surprised me. It also let me understand what is network bridge
and TAP device, which ... I couldn't get from Wikipedia. Speak of Wikipedia,
I think it never worked for me from ... since day 1, uh, the contents
are too ... "formal" ? Or no subjects ? I can't describe accurately.
These AI tools are great for doing "Getting Started" things I think.

## UEFI

Use `/usr/share/edk2/x64/OVMF_CODE.4m.fd` as a first read-only pflash drive.
Copy `/usr/share/edk2/x64/OVMF_VARS.4m.fd`, make it writable and use as a second writable pflash drive:

```
-drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd \
-drive if=pflash,format=raw,file=/copy/of/OVMF_VARS.4m.fd
```

Ref: [QEMU#Booting in UEFI mode](https://wiki.archlinux.org/title/QEMU#Booting_in_UEFI_mode)

## TPM

~~If you install Windows 10, you can skip this section.~~

>After satisfied all the requirements, finished the whole process, I found this:
>[Windows 11 IoT Enterprise LTSC 2024](https://massgrave.dev/windows_ltsc_links),
>which do not require TPM, UEFI and Secure boot.

>Then these hilarious things happened:\
>2024-12-04: [TPM 2.0 – a necessity for a secure and future-proof Windows 11](https://techcommunity.microsoft.com/blog/windows-itpro-blog/tpm-2-0-%E2%80%93-a-necessity-for-a-secure-and-future-proof-windows-11/4339066)\
>2024-12-10: [Installing Windows 11 on devices that don't meet minimum system requirements](https://support.microsoft.com/en-us/windows/installing-windows-11-on-devices-that-don-t-meet-minimum-system-requirements-0b2dc4a2-5933-4ad4-9c09-ef0a331518f1)

>What a clown. "Fuxk Microsoft !" Not my word, it's a line from the TV show "Space Force". ^_^

QEMU can emulate Trusted Platform Module, ~~which is required by Windows 11 (which requires TPM 2.0).~~

Ref: [QEMU#Trusted Platform Module emulation](https://wiki.archlinux.org/title/QEMU#Trusted_Platform_Module_emulation)

Install the [swtpm](https://archlinux.org/packages/?name=swtpm) package, which provides a software TPM implementation.
Create some directory for storing TPM data (`/path/to/mytpm` for example).
Run this command to start the emulator:

```
$ swtpm socket --tpm2 --tpmstate dir=/path/to/mytpm \
    --ctrl type=unixio,path=/path/to/mytpm/swtpm-sock
```

`/path/to/mytpm/swtpm-sock` will be created by swtpm: this is a UNIX socket to which QEMU will connect.
You can put it in any directory.

By default, swtpm starts a TPM version 1.2 emulator. The --tpm2 option enables TPM 2.0 emulation.

Finally, add the following options to QEMU:

```
$ qemu-system-x86_64 \
    -chardev socket,id=chrtpm,path=/path/to/mytpm/swtpm-sock \
    -tpmdev emulator,id=tpm0,chardev=chrtpm \
    -device tpm-tis,tpmdev=tpm0
```

and TPM will be available inside the virtual machine.
After shutting down the virtual machine, swtpm will be automatically terminated.

## Disk Image

If you store the hard disk images on a Btrfs file system, you should consider
disabling Copy-on-Write for the directory before creating any images.
Can be specified in option nocow for qcow2 format when creating image:

```
$ qemu-img create -f qcow2 win11.qcow2 -o nocow=on 120G
```

Ref: [QEMU#Creating a hard disk image](https://wiki.archlinux.org/title/QEMU#Creating_a_hard_disk_image)

## Enable KVM

```
$ qemu-system-x86_64 \
    -enable-kvm -machine q35
```

## CPU Memory

```
$ qemu-system-x86_64 \
    -cpu host -smp 4 -m 8G
```

## Networking

## Graphics Card

## Audio

## USB Path Through

