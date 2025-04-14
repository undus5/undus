+++
title       = "QEMU Install Windows 11 Guest"
lastmod     = 2025-03-22T12:17:00+08:00
date        = 2024-12-09
showSummary = true
showTOC     = true
weight      = 1000
+++

Use the low level tools directly.

<!--more-->

## Background

Libvirt is overkill for personal use. However, using the low level tool directly is not easy.
Normally I would go to the official website reading the documentation when trying
to learn some new tools, but this approach is not working well on QEMU, it's
[documentation](https://www.qemu.org/documentation/) is not friendly for beginners,
there's no "Getting Started" or "Tutorial", I didn't know where to start.
[Arch wiki](https://wiki.archlinux.org/title/QEMU) is better, but still not specific for me.
Google search, no luck either, everyone is using libvirt.

Then I asked ChatGPT for help with a simple phrase "qemu command for windows guest",
and it gave me a really good example with explaination, just one problem, it will
make things up when you trying to dig deeper by asking more details.
At the end, you always go back to the human written documentations for real study.
But it still finished a good job, let me understand what is network bridge
and TAP device, which I can't get from Wikipedia,
the contents on Wikipedia are hard to read, often lacking subjects.

This guide also works for other versions of Windows and Linux systems,
since Windows 11 is the most requirements needed OS, it can cover all the situations.

## Repository

I put the commands from this guide into a bash script.
When I finished it, I realized that I just implemented my own version of "libvirt",
so I call it [bashvirt](https://github.com/undus5/bashvirt).

## TPM

You can skip this section if you choose the
[IoT version of Windows 11](https://massgrave.dev/windows_ltsc_links)
, which does not require TPM, UEFI and Secure boot.

"QEMU can emulate Trusted Platform Module, which is required by Windows 11 (which requires TPM 2.0)."

Ref: [QEMU#Trusted Platform Module emulation](https://wiki.archlinux.org/title/QEMU#Trusted_Platform_Module_emulation)

"Install the [swtpm](https://archlinux.org/packages/?name=swtpm) package, which provides a software TPM implementation.
Create some directory for storing TPM data (`/path/to/mytpm` for example).
Run this command to start the emulator:"

```
$ swtpm socket --tpm2 --tpmstate dir=/path/to/mytpm \
    --ctrl type=unixio,path=/path/to/mytpm/swtpm-sock
```

"`/path/to/mytpm/swtpm-sock` will be created by swtpm: this is a UNIX socket to which QEMU will connect.
You can put it in any directory."

"By default, swtpm starts a TPM version 1.2 emulator. The --tpm2 option enables TPM 2.0 emulation."

"Finally, add the following options to QEMU:"

```
$ qemu-system-x86_64 \
    -chardev socket,id=chrtpm,path=/path/to/mytpm/swtpm-sock \
    -tpmdev emulator,id=tpm0,chardev=chrtpm \
    -device tpm-tis,tpmdev=tpm0
```

"and TPM will be available inside the virtual machine.
After shutting down the virtual machine, swtpm will be automatically terminated."

...

"Fuxk Microsoft !" --- A quote from the TV show "Space Force (2020)". ^_^

## UEFI

"Use `/usr/share/edk2/x64/OVMF_CODE.4m.fd` as a first read-only pflash drive.\
Copy `/usr/share/edk2/x64/OVMF_VARS.4m.fd`, make it writable and use as a second writable pflash drive:"

```
$ qemu-system-x86_64 \
    -drive if=pflash,format=raw,readonly=on,\
        file=/usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd \
    -drive if=pflash,format=raw,file=/copy/of/OVMF_VARS.4m.fd
```

Ref: [QEMU#Booting in UEFI mode](https://wiki.archlinux.org/title/QEMU#Booting_in_UEFI_mode)

## KVM, CPU, Mem

```
$ qemu-system-x86_64 \
    -enable-kvm -machine q35 \
    -cpu host -smp 4 -m 8G
```

Ref: [qemu(1)#machine](https://man.archlinux.org/man/qemu.1#machine)
, [qemu(1)#smp](https://man.archlinux.org/man/qemu.1#smp)

## VirtIO Driver

"QEMU offers guests the ability to use paravirtualized block and network devices
using the virtio drivers, which provide better performance and lower overhead."

This step is optional, you could skip this section if you just want a quick boot.

Download [virtio-win.iso](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso)
from [virtio-win GitHub](https://github.com/virtio-win/virtio-win-pkg-scripts/blob/master/README.md)

Ref: [QEMU#Installing virtio drivers](https://wiki.archlinux.org/title/QEMU#Installing_virtio_drivers)

## CDROM

```
$ qemu-system-x86_64 \
    -drive file=/path/to/windows11.iso,media=cdrom,if=none,id=cd0 \
    -device ide-cd,drive=cd0,bootindex=0 \
    -drive file=/path/to/virtio-win.iso,media=cdrom
```

Ref: [Managing device boot order with bootindex properties](https://www.qemu.org/docs/master/system/bootindex.html)

Without using bootindex, instead using `-cdrom -boot order=d`,
it will never boot from cdrom once the os installation has finished.
It's annoying when I want to redo the installation process.

## Disk Image

"If you store the hard disk images on a Btrfs file system, you should consider
disabling Copy-on-Write for the directory before creating any images.
Can be specified in option nocow for qcow2 format when creating image:"

```
$ qemu-img create -f qcow2 win11.qcow2 -o nocow=on 120G
$ qemu-system-x86_64 \
    -drive file=/path/to/win11.qcow2,if=none,id=disk0 \
    -device virtio-blk-pci,drive=disk0,bootindex=1
```

During installation, you need to load driver from virtio iso to let disk controller working.

If you just want a quick boot, and don't want bother with virtio,
use sata device instead,
it's a built-in emulation drive, no need extra settings to work:

```
$ qemu-system-x86_64 \
    -drive file=/path/to/win11.qcow2,if=none,id=disk0 \
    -device achi,id=achi0
    -device ide-hd,drive=disk0,bootindex=1,bus=achi0.0
```

Ref: [QEMU#Creating a hard disk image](https://wiki.archlinux.org/title/QEMU#Creating_a_hard_disk_image)

## Graphics Card

There're two options, one for booting from cdrom to install,
another for booting from disk image normally.

For cdrom booting:

```
$ qemu-system-x86_64 \
    -display sdl,gl=on,full-screen=on \
    -vga std 
```

For disk booting:

```
$ qemu-system-x86_64 \
    -display sdl,gl=on,full-screen=on \
    -device virtio-vga-gl
```

If you just want a quick boot, and don't want bother with virtio, keep using `-vga std`,
it's a built-in emulation drive, no need extra settings to work.

Ref: [QEMU#Graphics card](https://wiki.archlinux.org/title/QEMU#Graphics_card)

## Networking

If you just want a quick boot, and don't want bother with virtio,
you could use the following options instead, and skip the rest of the section:

```
$ qemu-system-x86_64 \
    -nic user,model=e1000
```

There're several types of network adapter in VirtualBox: NAT, Bridged, Host Only, Internal,
and I didn't know much about how they work in details back then.
After reading the arch wiki, I learned they are all bridged network in some ways.

Bridge is like a virtual switch connecting VM's virtual network interface
and the physical network interface.

Bridged Network:

"If you bridge together tap device and some host interface, such as eth0,
your virtual machines will appear directly on the external network,
which will expose them to possible attack. Depending on what resources your
virtual machines have access to, you may need to take all the precautions you
normally would take in securing a computer to secure your virtual machines.
If the risk is too great, virtual machines have little resources or you set up
multiple virtual machines, a better solution might be to use host-only networking
and set up NAT. In this case you only need one firewall on the host instead of
multiple firewalls for each guest."

Host Only Network:

"If the bridge is given an IP address and traffic destined for it is allowed,
but no real interface (e.g. eth0) is connected to the bridge, then the virtual machines
will be able to talk to each other and the host system. However, they will not
be able to talk to anything on the external network, provided that you do not set up
IP masquerading on the physical host."

Internal Network:

"If you do not give the bridge an IP address and add an iptables rule to drop
all traffic to the bridge in the INPUT chain, then the virtual machines will be
able to talk to each other, but not to the physical host or to the outside network."

Ref: [QEMU#Networking](https://wiki.archlinux.org/title/QEMU#Networking)

### Create Bridge

For systemd-networkd, create these files:

```
# /etc/systemd/network/25-br0.netdev

[NetDev]
Name=br0
Kind=bridge
```

```
# /etc/systemd/network/25-br0-ether.network

[Match]
Type=ether
Kind=!*

[Network]
Bridge=br0
```

```
# /etc/systemd/network/25-br0.network

[Match]
Name=br0

[Link]
RequiredForOnline=routable

[Network]
DHCP=yes
IPv4Forwarding=yes
```

Restart `systemd-networkd.service`:

```
$ sudo systemctl restart systemd-networkd
```

Ref: [Systemd-networkd#Configuration examples](https://wiki.archlinux.org/title/Systemd-networkd#Configuration_examples)
, [Systemd-networkd#Network bridge with DHCP](https://wiki.archlinux.org/title/Systemd-networkd#Network_bridge_with_DHCP)

The instructions above created a bridged network, which let virtual machines act
like real computers under the LAN, obtain IP addresses dynamically from the gateway.
If your network environment change frequently, for example you often move to different
working postions, then you IP addresses may vary, which is annoying when communicating
between the host and virtual machines.

To solve the problem, you may create another bridge, make it a host-only network.
The steps are similar, create `26-br1.netdev`, `26-br1.network`, exclude
`26-br1-ether.network`, then assign static IP address for `26-br1.network`,
replace `DHCP=yes` with `Address=192.168.123.1/24` or whatever private IP adress
you like. Then your virtual machine will have a second network interface card,
assign an IP address manually under the same subnet of `br1`, done. Now you can
communicate your host and virtual machines with these fixed IP address regardless
your public network environment.

You may want to have a DHCP server running on the bridge interface to service the virtual network.
Edit `26-br1.network`, append `DHCPServer=yes` to the [Network] section.

Ref:
[QEMU#Host-only networking](https://wiki.archlinux.org/title/QEMU#Host-only_networking)
, [Systemd-networkd#[DHCPServer]](https://wiki.archlinux.org/title/Systemd-networkd#[DHCPServer])
, [systemd.network(5)](https://man.archlinux.org/man/systemd.network.5#%5BDHCPSERVER%5D_SECTION_OPTIONS)

### Tap Devices

"The performance of virtual networking should be better with tap devices and bridges
than with user-mode networking or vde because tap devices and bridges are implemented in-kernel."

"In addition, networking performance can be improved by assigning virtual machines
a virtio network device rather than the default emulation of an e1000 NIC."

"Tap devices are a Linux kernel feature that allows you to create virtual network
interfaces that appear as real network interfaces. Packets sent to a tap interface
are delivered to a userspace program, such as QEMU, that has bound itself to the interface."

"Tap devices are supported by the Linux bridge drivers, so it is possible to bridge
together tap devices with each other and possibly with other host interfaces such as eth0.
This is desirable if you want your virtual machines to be able to talk to each other,
or if you want other machines on your LAN to be able to talk to the virtual machines."

`qemu-bridge-helper` can automatically create and delete tap devices also
bind them to bridge for VMs, via configuration:

```
# /etc/qemu/bridge.conf

allow br0
allow br1
...
```

Ref: [QEMU#Tap networking with QEMU](https://wiki.archlinux.org/title/QEMU#Tap_networking_with_QEMU)
, [QEMU#Bridged networking using qemu-bridge-helper](https://wiki.archlinux.org/title/QEMU#Bridged_networking_using_qemu-bridge-helper)


### Network Interface

```
$ qemu-system-x86_64 \
    -nic bridge,br=br0,model=virtio-net-pci,mac=52:54:xx:xx:xx:xx \
    -nic bridge,br=br1,model=virtio-net-pci,mac=52:54:xx:xx:xx:xx
```

Ref: [qemu(1)#nic](https://man.archlinux.org/man/qemu.1#nic)

Since QEMU by default will assign MAC addresses start from the same value
for every virtual machine's first NIC, which is 52:54:00:12:34:56,
then :57 :58 for the second and third NIC, it will cause conflict when
using bridged networking with multiple virtual machines.

To solve this problem, you can use the following bash script
to generate unique but fixed MAC address. Save it as `genmacaddr.sh`:

```
#!/usr/bin/bash
printf "${1}" | sha256sum |\
    awk -v offset="$(( ${2} + 7 ))" '{ printf "52:54:%s:%s:%s:%s\n", \
    substr($1,1,2), substr($1,3,2), substr($1,5,2), substr($1,offset,2) }'
```

Next, give your virtual machine a unique name, say "myvm1", then run:

```
$ ./genmacaddr.sh myvm1 1
$ ./genmacaddr.sh myvm1 2
$ ./genmacaddr.sh myvm1 3
```

The numbers represent to generate for the first, second, third NIC.

[QEMU#Link-level address caveat](https://wiki.archlinux.org/title/QEMU#Link-level_address_caveat)

## Audio

To list availabe audio backend drivers:

```
$ qemu-system-x86_64 \
    -audiodev help
```

Choose pulseaudio as backend for example:

```
$ qemu-system-x86_64 \
    -audiodev pa,id=snd0
```

`id` can be arbitrary name.

For Intel HD Audio emulation, add both controller and codec devices.\
To list the available Intel HDA Audio devices:

```
$ qemu-system-x86_64 -device help | grep hda
$ qemu-system-x86_64 \
    -device ich9-intel-hda \
    -device hda-duplex,audiodev=snd0
```

Ref: [QEMU#Audio](https://wiki.archlinux.org/title/QEMU#Audio)

## USB PassThrough

### USB udev rules

"When a kernel driver initializes a device, the default state of the device node is
to be owned by root:root, with permissions 600. This makes devices inaccessible to
regular users unless the driver changes the default, or a udev rule in userspace
changes the permissions."

"The modern recommended approach for systemd systems is to use a MODE of 660 to
let the group use the device, and then attach a TAG named uaccess. This special
tag makes udev apply a dynamic user ACL to the device node, which coordinates with
systemd-logind to make the device usable to logged-in users."

Allow regular user to use all USB devices:

```
# /etc/udev/rules.d/71-usb-uaccess.rules

SUBSYSTEM=="usb", MODE="0660", TAG+="uaccess"
```

"Note: For any rule adding the `uaccess` tag to be effective, the name of the file it is defined in
[has to lexically precede](https://github.com/systemd/systemd/issues/4288#issuecomment-348166161)
`/usr/lib/udev/rules.d/73-seat-late.rules`"

Reload new rules:

```
$ sudo udevadm control -R && sudo udevadm trigger
```

Ref: [Udev#Allowing regular users to use devices](https://wiki.archlinux.org/title/Udev#Allowing_regular_users_to_use_devices)
, [Udev#Loading new rules](https://wiki.archlinux.org/title/Udev#Loading_new_rules)

### QEMU Monitor

While QEMU is running, a monitor console is provided in order to provide several ways
to interact with the virtual machine running. The QEMU monitor offers interesting capabilities
such as obtaining information about the current virtual machine, hotplugging devices,
creating snapshots of the current state of the virtual machine, etc.
To see the list of all commands, run `help` or `?` in the QEMU monitor console or
review the relevant section of the official documentation
[QEMU Monitor](https://www.qemu.org/docs/master/system/monitor.html).

Run QEMU monitor with UNIX socket:

```
$ qemu-system-x86_64 \
    -monitor unix:/tmp/monitor.sock,server,nowait
```

Then you can connect with `socat`:

```
$ socat -,echo=0,icanon=0 UNIX-CONNECT:/tmp/monitor.sock
```

`echo=0,icanon=0` make keyboard interaction nicer here by preventing re-echoing of
entered commands and enabling Tab completion and arrow keys for history.

To send a one-shot command to QEMU, echo it thru socat to the UNIX socket:

```
$ echo "help" | socat - UNIX-CONNECT:/tmp/monitor.sock
```

Ref: [QEMU#UNIX socket](https://wiki.archlinux.org/title/QEMU#UNIX_socket)
, [Connect to running qemu instance with qemu monitor](https://unix.stackexchange.com/questions/426652/connect-to-running-qemu-instance-with-qemu-monitor)

### Passthrough

Start QEMU with XHCI USB controller support:

```
$ qemu-system-x86_64 \
    -device qemu-xhci
```

List host USB devices:

```
$ lsusb
...
Bus 003 Device 007: ID 0781:5406 SanDisk Corp. Cruzer Micro U3
```

Remeber device ID, use monitor socket to passthrough:

```
$ echo "device_add usb-host,vendorid=0x0781,productid=0x5406,id=usb1" | \
    socat - UNIX-CONNECT:/tmp/monitor.sock
```

`id` is required and can be arbitrary name, if missing , you will not able to detach the device.

List attached devices:

```
$ echo "info usb" | socat - UNIX-CONNECT:/tmp/monitor.sock
```

Detach device:

```
$ echo "device_del usb1" | socat - UNIX-CONNECT:/tmp/monitor.sock
```

Ref: [QEMU#Pass-through host USB device](https://wiki.archlinux.org/title/QEMU#Pass-through_host_USB_device)
, [USB Emulation](https://www.qemu.org/docs/master/system/devices/usb.html)
, [QemuDiskHotplug](https://wiki.ubuntu.com/QemuDiskHotplug)

