+++
title       = "QEMU Install Windows 11 Guest"
lastmod     = 2025-05-14T22:12:00+08:00
date        = 2024-12-09
showSummary = true
showTOC     = true
weight      = 1000
+++

Use the low level tools directly, get rid of complex middlewares.

<!--more-->

## Background

Libvirt is overkill for personal use, you could just start a virtual machine via
the `qemu-system-*` command with proper options.
However, using the low level tool directly is not easy.
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
the contents for technologis on Wikipedia are hard to read, often lacking subjects.

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
    -drive file=/path/to/win11.qcow2,if=none,id=disk0,format=qcow2 \
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

Resize disk image

```
$ qemu-img resize disk.qcow2 +10G
$ qemu-img resize --shrink disk.qcow2 -10G
```

Ref: [QEMU#Resizing an image](https://wiki.archlinux.org/title/QEMU#Resizing_an_image)

## Graphics Card

Use `VGA` for CDROM booting,
since there may no GPU drivers for qxl or virtio at the moment,
and specify a decent resolution for it, since the default resolution is very low:

```
$ qemu-system-x86_64 \
    -display gtk,gl=on,full-screen=on \
    -device VGA,xres=1920,yres=1080
```

After the system and proper drivers installed,
you can change to `qxl-vga` or `virtio-vga-gl`:

```
$ qemu-system-x86_64 \
    -display gtk,gl=on,full-screen=on \
    -device virtio-vga-gl

# or
    -device qxl-vga,xres=1920,yres=1080
```

If you just want a quick boot, and don't want bother with virtio, keep using `-vga std`,
it's a built-in emulation drive, no need extra settings to work.

Ref: [QEMU#Graphics card](https://wiki.archlinux.org/title/QEMU#Graphics_card)

## Mouse Integration

If use GTK based display, you may need to enable tablet mode for mouse to work:

```
$ qemu-system-x86_64 \
    -usb -device usb-tablet
```

or use `qemu-xhci` for USB 3.0 support:

```
$ qemu-system-x86_64 \
    -device qemu-xhci -device usb-tablet
```

or use `usb-ehci` for only USB 2.0 support, since Windows 7 do not support USB 3.0:

```
$ qemu-system-x86_64 \
    -device usb-ehci -device usb-tablet
```

Ref: [QEMU#Mouse integration](https://wiki.archlinux.org/title/QEMU#Mouse_integration)
, [QEMU#Not grabbing mouse input](https://wiki.archlinux.org/title/QEMU#Not_grabbing_mouse_input)
, [USB emulation](https://qemu-project.gitlab.io/qemu/system/devices/usb.html)

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

The following instructions setup a bridged network, which let virtual machines act
like real computers under the LAN, obtain IP addresses dynamically from the gateway (home router).

For systemd-networkd, suppose your network interface is enp0s1, create these files:

```
# /etc/systemd/network/25-brlan.netdev
[NetDev]
Name=brlan
Kind=bridge
```

```
# /etc/systemd/network/25-brlan.network
[Match]
Name=brlan
[Link]
RequiredForOnline=routable
[Network]
DHCP=yes
IPv4Forwarding=yes
[DHCPv4]
RouteMetric=128
```

```
# /etc/systemd/network/25-brlan-en.network
[Match]
Name=enp0s1
[Network]
Bridge=brlan
```

Systemd-networkd does not set per-interface-type default route metrics.
If you have multiple physical network cards of same type, say 2 wired network cards,
you must specific different `RouteMetric` for them, or the "race condition"
will cause extreamly slow network connections.

Ref:
[Systemd-networkd#Prevent multiple default routes](https://wiki.archlinux.org/title/Systemd-networkd#Prevent_multiple_default_routes)

Restart `systemd-networkd.service`:

```
$ sudo systemctl restart systemd-networkd
```

Ref: [Systemd-networkd#Configuration examples](https://wiki.archlinux.org/title/Systemd-networkd#Configuration_examples)
, [Systemd-networkd#Network bridge with DHCP](https://wiki.archlinux.org/title/Systemd-networkd#Network_bridge_with_DHCP)

Since you don't want virtual machines exposed on the LAN, or you just want to
use fixed IP addresses between host and virtual machines, you could setup a
host only network:

```
# /etc/systemd/network/26-brnat.netdev
[NetDev]
Name=brnat
Kind=bridge
```

```
# /etc/systemd/network/26-brnat.network
[Match]
Name=brnat
[Network]
IPv4Forwarding=yes
IPMasquerade=yes
DHCPServer=true
Address=10.9.8.7/24
[DHCPServer]
DNS=10.9.8.7
[DHCPv4]
RouteMetric=256
```

Ref:
[QEMU#Host-only networking](https://wiki.archlinux.org/title/QEMU#Host-only_networking)
, [Systemd-networkd#[DHCPServer]](https://wiki.archlinux.org/title/Systemd-networkd#[DHCPServer])
, [systemd.network(5)](https://man.archlinux.org/man/systemd.network.5#%5BDHCPSERVER%5D_SECTION_OPTIONS)
, [systemd.netdev(5)](https://man.archlinux.org/man/systemd.netdev.5)

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

allow brlan
allow brnat
...
```

Ref: [QEMU#Tap networking with QEMU](https://wiki.archlinux.org/title/QEMU#Tap_networking_with_QEMU)
, [QEMU#Bridged networking using qemu-bridge-helper](https://wiki.archlinux.org/title/QEMU#Bridged_networking_using_qemu-bridge-helper)


### Network Interface

```
$ qemu-system-x86_64 \
    -nic bridge,br=brlan,model=virtio-net-pci,mac=52:54:xx:xx:xx:xx \
    -nic bridge,br=brnat,model=virtio-net-pci,mac=52:54:xx:xx:xx:xx
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

Allow regular user to use all USB devices,
create `/etc/udev/rules.d/71-usb-uaccess.rules` with:

```
SUBSYSTEM=="usb", MODE="0660", TAG+="uaccess"
```

"Note: For any rule adding the `uaccess` tag to be effective, the name of the file it is defined in
[has to lexically precede](https://github.com/systemd/systemd/issues/4288#issuecomment-348166161)
`/usr/lib/udev/rules.d/73-seat-late.rules`"

Apply new rules:

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

## File Sharing

virtiofsd is a modern and high-performance way to share files between host and guest,
it has nearly naive performance, way faster than the traditional ways based on
network protocols such as ssh and samba.

"virtiofsd is shipped with the [virtiofsd](https://archlinux.org/packages/?name=virtiofsd) package."

"Example use case: virtiofsd runs unprivileged with UID:GID 1001:100.  It cannot change its own UID/GID, so attempting to
let the guest create files with any other UID/GID combination will fail.  By using --translate-uid and
--translate-gid, however, a mapping from guest UIDs/GIDs can be set up such that virtiofsd will create files under the
only combination that it can, which is 1001:100.  For example, to allow any guest user to create a file, we can squash
everything to 1001:100, which will create all those files as 1001:100 on the host.  In the guest, we may want to have
those files appear as 1000:1000, though, and all other UIDs and GIDs should be visible unchanged in the guest.  That
would look like so:"

```
$ /usr/lib/virtiofsd \
    --socket-path path/to/myviofsd.sock \
    --shared-dir path/to/shared_dir \
    --sandbox namespace \
    --translate-uid host:1001:1000:1 \
    --translate-gid host:100:1000:1 \
    --translate-uid squash-guest:0:1000:4294967295 \
    --translate-gid squash-guest:0:1000:4294967295 \
```

Corresponding QEMU options:

```
$ vm_memory=4G
$ qemu-system-x86_64 \
    -m ${vm_memory}
    -object memory-backend-memfd,id=mem,size=${vm_memory},share=on
    -numa node,memdev=mem \
    -chardev socket,id=charviofsd,path=/path/to/myviofsd.sock
    -device vhost-user-fs-pci,chardev=charviofsd,tag=myviofsd
```

- `size=4G` must match the size specified with `-m 4G` option
- `myviofsd` is an identifier that you will use later in the guest to mount the share
- multiple vms can share the same folder with same tag, but every vm needs to start its own virtiofsd service,
means specifing a unique socket file, and virtiofsd will be terminated automatically after shutting down the vm.

On Windows guest, install virtio driver first (ref to section: [virtio-driver](#virtio-driver)),
then download and install [WinFsp](https://winfsp.dev/rel/), start `VirtIO-FS Service`, enable autostart if necessary.
After starting the service, go to Explorer -> This PC, you could see a `Z:` drive, which is the shared folder,
if not showing, check virtiofsd options and errors.

On Linux guest, mount with:

```
$ sudo mount -t virtiofs myviofsd ~/myviofsd
```

Ref: [QEMU#Host file sharing with virtiofsd](https://wiki.archlinux.org/title/QEMU#Host_file_sharing_with_virtiofsd)
, [virtiofsd README](https://gitlab.com/virtio-fs/virtiofsd/-/blob/main/README.md?ref_type=heads)
, [virtiofs](https://virtio-fs.gitlab.io/)

## Hyper-V Enlightenments

Ref: [QEMU#Improve virtual machine performance](https://wiki.archlinux.org/title/QEMU#Improve_virtual_machine_performance)
, [Hyper-V Enlightenments](https://www.qemu.org/docs/master/system/i386/hyperv.html)

"In some cases when implementing a hardware interface in software is slow,
KVM implements its own paravirtualized interfaces. This works well for Linux as
guest support for such features is added simultaneously with the feature itself.
It may, however, be hard-to-impossible to add support for these interfaces to
proprietary OSes, namely, Microsoft Windows."

"KVM on x86 implements Hyper-V Enlightenments for Windows guests.
These features make Windows and Hyper-V guests think they’re running on top of a
Hyper-V compatible hypervisor and use Hyper-V specific features."

```
$ opts="hv_relaxed,hv_vapic,hv_spinlocks=0xfff"
$ opts="${opts},hv_relaxed,hv_vapic,hv_spinlocks=0xfff"
$ opts="${opts},hv_vpindex,hv_synic,hv_time,hv_stimer"
$ opts="${opts},hv_tlbflush,hv_tlbflush_ext,hv_ipi,hv_stimer_direct"
$ opts="${opts},hv_runtime,hv_frequencies,hv_reenlightenment"
$ opts="${opts},hv_avic,hv_xmm_input"
$ qemu-system-x86_64 \
    -cpu host,${opts}
```

If your CPU is Intel, also append "hv_evmcs".

## Windows VM Optimization

Disable SuperFetch. Type "services" in search box and open, find "SysMain" service, disable it.

Disable ScheduledDefrag. Type "task scheduler" in search box and open, find `Microsoft\Windows\Defrag`, disable it.

Disable useplatformclock. Right click start menu, select Windows Powershell (Admin), run `bcdedit /set useplatformclock No`.

Disable unnecessary startups from `Settings -> Apps -> Startup`.

Ref: [How To PROPERLY Install Windows 11 on KVM (2024)](https://www.youtube.com/watch?v=7tqKBy9r9b4)

## Boot From Physical Disk

To boot from physical disk, only one thing need to do, which is configuring udev rules
for that disk device, give it normal user access permission, similar as section
[USB udev rules](#usb-udev-rules).

Assume the device is /dev/sdb, first we need to get necessary info about it:

```
$ udevadm info --attribute-walk --name=/dev/sdb
```

The output is like:

```
looking at device '/devices/pci0000:00/.../target1:0:0/1:0:0:0/block/sdb':
    KERNEL=="sdb"
    SUBSYSTEM=="block"
    ...
looking at parent device '/devices/pci0000:00/.../target1:0:0/1:0:0:0':
    KERNELS=="1:0:0:0"
    SUBSYSTEMS=="scsi"
    ...
    ATTRS{model}=="SSD 32GB        "
    ...
    ATTRS{vendor}=="ATA     "
    ...
```

Combine proper attributes to let udev rules only applying to this specific device,
create `/etc/udev/rules.d/51-ssd32g-uaccess.rules` with:

```
KERNEL=="sd*", SUBSYSTEM=="block", SUBSYSTEMS=="scsi", \
ATTRS{model}=="SSD 32GB*", ATTRS{vendor}=="ATA*", \
MODE="0660", TAG+="uaccess"
```

Apply new rules:

```
$ sudo udevadm control -R && sudo udevadm trigger
```

Boot qemu with raw format:

```
$ qemu-system-x86_64 \
    -drive file=/dev/sdb,if=none,id=disk0,format=raw \
    -device virtio-blk-pci,drive=disk0,bootindex=1
```

Ref: [Udev#udev rule example](https://wiki.archlinux.org/title/Udev#udev_rule_example)

