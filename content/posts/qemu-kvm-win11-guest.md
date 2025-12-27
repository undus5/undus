+++
aliases     = "/posts/qemu-install-windows11-guest/"
title       = "QEMU/KVM: Windows 11 Guest"
lastmod     = 2025-12-27
date        = 2024-12-09
showSummary = true
showTOC     = true
weight      = 1000
+++

Use low level tools directly, get rid of complex middlewares.

<!--more-->

## Background

Libvirt is overkill for personal use, you could just run `qemu-system-x86_64`
command with proper options to start a virtual machine.
However, using low level tools directly is not always easy.
Normally I would read documentations from official websites of these tools
to learn how to, but this approach is not working well for QEMU, its
[documentation](https://www.qemu.org/documentation/) is not friendly for beginners,
there's no "Getting Started" or "Tutorial", I didn't know where to start.
[Arch wiki](https://wiki.archlinux.org/title/QEMU) is better, but still not
friendly enough if you are totaly newbie in this area.
Google search, no luck either, everyone is using libvirt.

Then I asked ChatGPT for help with a simple phrase "qemu command for windows guest",
and it gave me a really good example with explaination, just one problem, it will
make things up when you trying to dig deeper by asking more details.
At the end, you always go back to the human written documentations for real study.
But it still finished a good job, let me understand e.g. what is network bridge
and TAP device, which I can't understand from Wikipedia,
the contents for technologis on Wikipedia are hard to read, often lacking subjects.

This guide also works for other versions of Windows and Linux systems,
since Windows 11 is the most requirements needed OS, it can cover all the situations.

## Repository

I put the commands from this guide into a bash script.
When I finished it, I realized that I just implemented my own version of "libvirt",
so I call it [bashvirt](https://github.com/undus5/bashvirt).

## Convention

This guide assumes all the runtime files of the virtual machine are under
`/data/vms/win11/`.

## CPU Memory

```
$ qemu-system-x86_64 -enable-kvm -machine q35 -cpu host -smp 4 -m 8G
```

`-smp`: cpu cores, `-m`: memory size.

Ref: [qemu(1)#machine](https://man.archlinux.org/man/qemu.1#machine)
, [qemu(1)#smp](https://man.archlinux.org/man/qemu.1#smp)

## TPM

You can skip this section if you choose the
[IoT version of Windows 11](https://massgrave.dev/windows_ltsc_links)
, which does not require TPM, UEFI and Secure boot.

![Fuck Microsoft from Space Force (2020)](/images/fuck-microsoft-from-space-force-2020.webp)

--- From the TV show "Space Force (2020)" :)

Install `swtpm` package, which is a
[TPM emulator](https://wiki.archlinux.org/title/QEMU#Trusted_Platform_Module_emulation).

Start the emulator:

```
(user)$ swtpm socket --tpm2 \
    --tpmstate dir=/data/vms/win11 \
    --ctrl type=unixio,path=/data/vms/win11/swtpm.sock
```

`swtpm.sock` will be created automatically.

QEMU options for swtpm:

```
(user)$ qemu-system-x86_64 \
    ... \
    -chardev socket,id=chrtpm,path=/data/vms/win11/swtpm.sock \
    -tpmdev emulator,id=tpm0,chardev=chrtpm -device tpm-tis,tpmdev=tpm0
```

Swtpm will be automatically terminated after the virtual machine shutting down.

## UEFI

Copy OVMF variable file:

```
(user)$ cp /usr/share/edk2/x64/OVMF_VARS.4m.fd /data/vms/win11/
```

QEMU options for UEFI:

```
(user)$ qemu-system-x86_64 \
    ... \
    -drive if=pflash,format=raw,readonly=on,\
        file=/usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd \
    -drive if=pflash,format=raw,file=/data/vms/win11/OVMF_VARS.4m.fd
```

Ref: [QEMU#Booting in UEFI mode](https://wiki.archlinux.org/title/QEMU#Booting_in_UEFI_mode)

## VirtIO Driver

For better performance, you should
[use virtio drivers](https://wiki.archlinux.org/title/QEMU#Using_virtio_drivers)
for disk and network interface.
Download `virtio-win.iso` from
[virtio-win GitHub](https://github.com/virtio-win/virtio-win-pkg-scripts/blob/master/README.md).

## CDROM

```
(user)$ qemu-system-x86_64 \
    ... \
    -drive file=/data/downloads/win11.iso,media=cdrom,if=none,id=cd0 \
    -device ide-cd,drive=cd0,bootindex=0 \
    -drive file=/data/downloads/virtio-win.iso,media=cdrom
```

This will let the virtual machine boot from `win11.iso` and mount
`virtio-win.iso` as second CDROM.

There's a shorter way to set bootable CDROM `-cdrom <iso_file> -boot order=d`
instead of `-drive ...if=none -device ... bootindex=0`, but it has a drawback,
the virtual machine will never boot from CDROM once the os installation
has finished, which is annoying when you want to redo the installation process.

Ref: [Managing device boot order with bootindex properties](https://www.qemu.org/docs/master/system/bootindex.html)

## Disk Image

```
(user)$ qemu-img create -f qcow2 disk.qcow2 -o nocow=on 120G
(user)$ qemu-system-x86_64 \
    ... \
    -drive file=/data/vms/win11/disk.qcow2,if=none,id=disk0,format=qcow2 \
    -device virtio-blk-pci,drive=disk0,bootindex=1
```

`nocow=on`: disable Copy-on-Write for qcow2 format if use BTRFS.

Since we use virtio storage device here, you need to load driver from
`virtio-win.iso` to let disk controller working during system installation.

If you don't want to bother with virtio, just want a quick boot,
use sata device instead, it's a built-in emulation drive,
no need extra settings to work:

```
(user)$ qemu-system-x86_64 \
    ... \
    -drive file=/data/vms/win11/disk.qcow2,if=none,id=disk0 \
    -device achi,id=achi0
    -device ide-hd,drive=disk0,bootindex=1,bus=achi0.0
```

Ref: [QEMU#Creating a hard disk image](https://wiki.archlinux.org/title/QEMU#Creating_a_hard_disk_image)

---

How to enlarge disk image:

```
(user)$ qemu-img resize disk.qcow2 +10G
```

After enlarging the disk image, you may want to boot into the virtual machine and
extend the main partition, but when you open the disk management tool, you may
find there is a recovery partition sitting between the main volume and
unallocated space, here's how to delete it: right click the start menu,
select "Windows Powershell (Admin)", type:

```
C:\...> diskpart
DISKPART> list disk
DISKPART> select disk 0
DISKPART> list partition
DISKPART> select partition 4
DISKPART> delete partition override
DISKPART> list volume
DISKPART> select volume 1
DISKPART> extend
DISKPART> exit
```

Replace the numbers with your own, type `help` to list available commands.

---

Before shrinking disk image, you need to do some work inside the Windows
virtual machine first, using
[sdelete](https://learn.microsoft.com/en-us/sysinternals/downloads/sdelete)
to zero out free space: `sdelete -z C:`, then shrink volume via disk management
tool, and last, shutdown the virtual machine and shrink the disk image:

```
(user)$ qemu-img resize --shrink disk.qcow2 -10G
```

Ref: [QEMU#Resizing an image](https://wiki.archlinux.org/title/QEMU#Resizing_an_image)

## Networking

If you don't want to bother with virtio, just want a quick boot,
you could use the following options instead, and skip the rest of this section:

```
(user)$ qemu-system-x86_64 \
    ... \
    -nic user,model=e1000
```

### Network Interface

```
(user)$ qemu-system-x86_64 \
    ... \
    -nic bridge,br=brlan,model=virtio-net-pci,mac=52:54:xx:xx:xx:xx \
    -nic bridge,br=brnat,model=virtio-net-pci,mac=52:54:xx:xx:xx:xx
```

Ref: [qemu(1)#nic](https://man.archlinux.org/man/qemu.1#nic)

Since QEMU by default will assign MAC addresses start from the same value
for every virtual machine's first NIC, which is 52:54:00:12:34:56,
then :57, :58 for the second and third NIC, it will cause conflict when
using bridged networking with multiple virtual machines. Their addresses
should be unique and consistent.

To solve this problem, you can use the following bash script
to generate unique but fixed MAC address. Save it as `gen-mac.sh`:

```
#!/bin/bash
_niclabel="${1}"
_hash=$(printf "${_niclabel}" | sha256sum)
echo "52:54:${_hash:0:2}:${_hash:2:2}:${_hash:4:2}:${_hash:6:2}"
```

Next, give your virtual machine nic a unique name, say "vm1:brlan", then run:

```
(user)$ ./gen-mac.sh vm1:brlan
(user)$ ./gen-mac.sh vm1:brnat
(user)$ ./gen-mac.sh vm2:brlan
```

Ref: [QEMU#Link-level address caveat](https://wiki.archlinux.org/title/QEMU#Link-level_address_caveat)

### Bridged Network

There're several types of network adapter in VirtualBox: NAT, Bridged, Host Only, Internal,
and I didn't know much about how they work in details back then.
After reading the arch wiki, I learned they are all bridged network in some ways.
Bridge is like a virtual switch connecting VM's virtual network interfaces
with the physical network interfaces.

Bridged Network: The bridge is attached to physical network interface,
virtual machines will appear in your Local Area Network (LAN), acting like real
machines, can be accessed by other devices in LAN.

Host Only Network: The bridge is not attached to physical network interface,
but given an IP address, and virtual machines are assigned IPs with
the same range of the bridge's IP. Then virtual machines can talk to each other
and the host system. By default VMs cannot access the internet,
but this ability can be enabled by configuring nftables NAT rules on host system.

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
(root)# systemctl restart systemd-networkd
```

Ref:
[Systemd-networkd#Network bridge with DHCP](https://wiki.archlinux.org/title/Systemd-networkd#Network_bridge_with_DHCP)

---

You can let the bridge inherit MAC address from the bridged physical interfaces:

```
# /etc/systemd/network/25-brlan.netdev
[NetDev]
Name=brlan
Kind=bridge
MACAddress=none
```

```
# /etc/systemd/network/25-brlan.link
[Match]
OriginalName=brlan

[Link]
MACAddressPolicy=none
```

Ref:
[Systemd-networkd#Inherit_MAC_address](https://wiki.archlinux.org/title/Systemd-networkd#Inherit_MAC_address_(optional))

---

If you don't want virtual machines exposed on the LAN, or you just want to
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
PoolOffset=100
PoolSize=100

[DHCPv4]
RouteMetric=256
```

---

Since our virtual machines now have pretty consistent MAC addresses, we can give
them static IP addresses via `26-brnat.network`:

```
...
[DHCPServerStaticLease]
MACAddress=52:54:00:12:34:56
Address=10.9.8.256
[DHCPServerStaticLease]
MACAddress=52:54:00:12:34:78
Address=10.9.8.278
...
```

There's a more flexible way to keep track of virtual machines' IP addresses
even they are dynamic, which is using network scanning tools to search,
e.g. `arp-scan`:

```
(user)$ arp-scan -x -l -I brnat | grep 52:54:00:12:34:56
```

---

If you've cloned your virtual machine, you may find they were getting the same
IP addresse even we gave them unique MAC address, this is because the default DHCP
client identifier using by systemd is DUID, which is `/etc/machine-id`.
There're two methods to solve this:

1, Change identifier type, edit `/etc/systemd/network/26-brnat.network`:

```
...
[DHCPv4]
ClientIdentifier=mac
...
```

2, Reset machine-id, then reboot:

```
(root)# rm /etc/machine-id
(root)# dbus-uuidgen --ensure=/etc/machine-id
(root)# rm /var/lib/dbus/machine-id
(root)# dbus-uuidgen --ensure
```

Ref:
[QEMU#Host-only networking](https://wiki.archlinux.org/title/QEMU#Host-only_networking)
, [Systemd-networkd#[DHCPServer]](https://wiki.archlinux.org/title/Systemd-networkd#[DHCPServer])
, [systemd.network(5)](https://man.archlinux.org/man/systemd.network.5#%5BDHCPSERVER%5D_SECTION_OPTIONS)
, [systemd.netdev(5)](https://man.archlinux.org/man/systemd.netdev.5)

### TAP Devices

The performance of QEMU's default emulation network interface is limited,
you should use TAP device for better performance instead, combine with virtio
network device, it can reach to nearly native speed.

TAP devices are a Linux kernel feature that allows you to create virtual network
interfaces that appear as real network interfaces, each one corresponding to a
network interface of some virtual machine. We bridge together TAP devices with
each other and with host interfaces to build bridged network, host only network
and internal network.

`qemu-bridge-helper` can automatically create, delete TAP devices and
bind them to bridges for virtual machines,
via configuration in `/etc/qemu/bridge.conf`:

```
allow brlan
allow brnat
```

Ref: [QEMU#Tap networking with QEMU](https://wiki.archlinux.org/title/QEMU#Tap_networking_with_QEMU)
, [QEMU#Bridged networking using qemu-bridge-helper](https://wiki.archlinux.org/title/QEMU#Bridged_networking_using_qemu-bridge-helper)

## Graphics Card

Use the standard basic `VGA` graphic device for CDROM booting,
since there may no GPU drivers for qxl or virtio at the moment,
and specify a decent resolution for it, since the default resolution is very low:

```
(user)$ qemu-system-x86_64 \
    ... \
    -device VGA,xres=1920,yres=1080 \
    -display sdl,gl=on,full-screen=on
```

After the system and proper drivers installed,
you can change `VGA` to `qxl-vga` or `virtio-vga-gl`:

Ref: [QEMU#Graphics card](https://wiki.archlinux.org/title/QEMU#Graphics_card)

## Audio

To list available audio backend drivers:

```
(user)$ qemu-system-x86_64 -audiodev help
```

Choose pipewire as backend for example:

```
(user)$ qemu-system-x86_64 \
    ... \
    -audiodev pipewire,id=snd0
```

`id` can be arbitrary name.

For Intel HD Audio emulation, add both controller and codec devices.\
To list the available Intel HDA Audio devices:

```
(user)$ qemu-system-x86_64 -device help | grep hda
(user)$ qemu-system-x86_64 \
    ... \
    -device ich9-intel-hda \
    -device hda-output,audiodev=snd0
```

Ref: [QEMU#Audio](https://wiki.archlinux.org/title/QEMU#Audio)

## USB Support

Enable USB controller with `-device qemu-xhci` for USB 3.0 support, or with
`-usb` for better compatibility since Windows 7 does not support USB 3.0.

Ref: [USB emulation](https://qemu-project.gitlab.io/qemu/system/devices/usb.html)

## Mouse Integration

The display window could be `sdl` or `gtk`.

If use GTK based display, you may need to enable tablet mode for mouse to work:

```
(user)$ qemu-system-x86_64 \
    ... \
    -usb -device usb-tablet
```

Ref: [QEMU#Mouse integration](https://wiki.archlinux.org/title/QEMU#Mouse_integration)
, [QEMU#Not grabbing mouse input](https://wiki.archlinux.org/title/QEMU#Not_grabbing_mouse_input)

## QEMU Monitor

While QEMU is running, a monitor console is provided in order to provide several ways
to interact with the running virtual machine. The QEMU monitor offers interesting capabilities
such as obtaining information about the current virtual machine, hotplugging devices,
creating snapshots of the current state of the virtual machine, etc.
To see the list of all commands, run `help` or `?` in the QEMU monitor console or
review the relevant section of the official documentation
[QEMU Monitor](https://www.qemu.org/docs/master/system/monitor.html).

Run virtual machine with QEMU monitor opened via UNIX socket:

```
(user)$ qemu-system-x86_64 \
    ... \
    -monitor unix:/data/vms/win11/qemu-monitor.sock,server,nowait
```

Then you can connect it with `socat`:

```
(user)$ socat -,echo=0,icanon=0 UNIX-CONNECT:/data/vms/win11/qemu-monitor
```

`echo=0,icanon=0` make keyboard interaction nicer here by preventing re-echoing of
entered commands and enabling Tab completion and arrow keys for history.
To disconnect, press `Ctrl-c`, don't use `quit` command, it will force quit the
virtual machine immediately.

To send a one-shot command to QEMU, echo it through socat to the UNIX socket:

```
(user)$ echo "help" | socat - UNIX-CONNECT:/tmp/monitor.sock
```

Ref: [QEMU#UNIX socket](https://wiki.archlinux.org/title/QEMU#UNIX_socket)
, [Connect to running qemu instance with qemu monitor](https://unix.stackexchange.com/questions/426652/connect-to-running-qemu-instance-with-qemu-monitor)

Useful qemu monitor commands to send:

```
(qemu) sendkey ctrl-alt-f2
(qemu) system_reset
```

Ref: [QEMU#Sending keyboard presses](https://wiki.archlinux.org/title/QEMU#Sending_keyboard_presses_to_the_virtual_machine_using_the_monitor_console)
, [QEMU#Power options](https://wiki.archlinux.org/title/QEMU#Pause_and_power_options_via_the_monitor_console)

## USB Passthrough

First enable USB controller support for virtual machine,
refer to section [USB Support](#usb-support).

List host USB devices:

```
(user)$ lsusb
...
Bus 003 Device 007: ID 0781:5406 SanDisk Corp. Cruzer Micro U3
```

If command not found, install package [usbutils](https://archlinux.org/packages/?q=usbutils).

Remeber device ID, use monitor socket to passthrough:

```
(user)$ _qexec="device_add usb-host,vendorid=0x0781,productid=0x5406,id=usb1"
(user)$ echo "${_qexec}" | socat - UNIX-CONNECT:/data/vms/win11/qemu-monitor.sock
```

`id=` is required, if missing, you will not able to detach the device, it can not
be arbitrary name according to my experiment (didn't find any description in documents),
I guess it is limited to the form similar to naming a variable,
which is must started with letters, may have numbers followed.

List attached devices:

```
$ echo "info usb" | socat - UNIX-CONNECT:/data/vms/win11/qemu-monitor.sock
```

Detach device:

```
$ echo "device_del usb1" | socat - UNIX-CONNECT:/data/vms/win11/qemu-monitor.sock
```

Ref: [QEMU#Pass-through host USB device](https://wiki.archlinux.org/title/QEMU#Pass-through_host_USB_device)
, [USB Emulation](https://www.qemu.org/docs/master/system/devices/usb.html)
, [QemuDiskHotplug](https://wiki.ubuntu.com/QemuDiskHotplug)

## File Sharing (Virtiofs)

virtiofsd is a modern and high-performance way to share files between host and guest,
it has nearly naive performance, way faster than the traditional ways based on
network protocols such as ssh and samba. Install `virtiofsd` package to use.

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

You may get warning message:

> Failure when trying to set the limit to 1000000, the hard limit (524288) of open file descriptors is used instead.

To fix it, remove open file descriptors limit for regular user via
`/etc/security/limits.conf`:

```
user1 - nofile unlimited
```

Replace `user1` with your regular user's name.
Ref: [limit.conf(5)](https://man.archlinux.org/man/limits.conf.5).

Check whether new memlock limit configuration is applied:

```
(user)$ ulimit -Hn
```

Corresponding QEMU options:

```
$ _memory=4G
$ qemu-system-x86_64 \
    ... \
    -m ${_memory}
    -object memory-backend-memfd,id=mem,size=${_memory},share=on
    -numa node,memdev=mem \
    -chardev socket,id=viofschar,path=/data/vms/win11/virtiofsd.sock
    -device vhost-user-fs-pci,chardev=viofschar,tag=viofstag
```

- `size=4G` must match the size specified with `-m 4G` option
- `viofstag` is an identifier that you will use later in the guest to mount the share
- multiple vms can share the same folder with same tag, but every vm needs to start its own virtiofsd service,
means specifing a unique socket file, and virtiofsd will be terminated automatically after the vm shutting down.

On Windows guest, install virtio driver first (ref to section: [virtio-driver](#virtio-driver)),
then download and install [WinFsp](https://winfsp.dev/rel/), start `VirtIO-FS Service`, enable autostart if necessary.
After starting the service, go to Explorer -> This PC, you could see a `Z:` drive, which is the shared folder,
if not showing, check virtiofsd options and errors.

On Linux guest, mount with:

```
(root)# mount -t virtiofs viofstag ~/virtiofs
```

Ref: [QEMU#Host file sharing with virtiofsd](https://wiki.archlinux.org/title/QEMU#Host_file_sharing_with_virtiofsd)
, [virtiofsd README](https://gitlab.com/virtio-fs/virtiofsd/-/blob/main/README.md?ref_type=heads)
, [virtiofs](https://virtio-fs.gitlab.io/)

## GPU Passthrough

For GPU Passthrough, avoid AMD GPU because of the "reset bug".

First enable IOMMU in BIOS.
For Intel CPU, add kernel parameter `intel_iommu=on`.
For AMD CPU, no need extra settings.

Check whether IOMMU is enabled:

```
(root)# dmesg | grep -i IOMMU
```

Check IOMMU groups via script `iommu-groups.sh`:

```
#!/bin/bash
shopt -s nullglob
for g in $(find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V); do
    echo "IOMMU Group ${g##*/}:"
    for d in $g/devices/*; do
        echo -e "\t$(lspci -nns ${d##*/})"
    done;
done;
```

The minimal unit for PCI passthrough is IOMMU group, so if your GPU is under
the same group with other devices, maybe consider to replace the motherboard
to a IOMMU friendly one, such as X570 series for AM4 socket or refer to
https://iommu.info.

To isolate and bind GPU device, remeber GPU device and corresponding
audio device's IDs, they are look like `[10de:1d02]`, add them to
`vfio-pci` kernel module config file by creating `/etc/modprobe.d/vfio-pci.conf`:

```
options vfio-pci ids=10de:1d02,10de:0fb8
```

Load `vfio-pci` module early via dracut by creating
`/etc/dracut.conf.d/10-vfio.conf`:

```
force_drivers+=" vfio_pci vfio vfio_iommu_type1 "
```

Reboot and verify vfio-pci has loaded properly and bound to the right devices:

```
(root)# dmesg | grep -i vfio
# or
(user)$ lspci -nnk -d 10de:1d02
```

### Non-Root Permission

Since we were running QEMU with regular user, we need to solve some
permission problems before we assign the GPU to virtual machine.

First, we need to give regular user permission to access vfio devices,
by append udev rule into `/etc/udev/rules.d/50-uaccess.rules`:

```
SUBSYSTEM=="vfio", MODE="0660", TAG+="uaccess"
```

Apply new rules:

```
(root)# udevadm control -R && udevadm trigger
```

Ref: [Udev Rules](#udev-rules)

Second, remove `memlock` limit for regular user via `/etc/security/limits.conf`:

```
user1 - memlock unlimited
```

Replace `user1` with your regular user's name.
Ref: [limit.conf(5)](https://man.archlinux.org/man/limits.conf.5).

Check whether new memlock limit configuration is applied:

```
(user)$ ulimit -Hl
```

If you don't remove this limit, you may encounter error message like this:

> failed to setup container for group 20: memory listener initialization failed: Region mem: vfio_container_dma_map

Add isolated GPU to virtual machine, remeber GPU device's PCI address from
IOMMU group, it looks like `03:00.0`, add it into QEMU options:

```
(user)$ qemu-system-x86_64 \
    ... \
    -device vfio-pci,host=03:00.0
```

No need to add audio device ID here, it can be handled automatically.

There's conflict between `vfio-pci` and `virtio-vga-gl`, only one can exist,
but `vfio-pci` can coexist with standard `VGA` device.

Ref:\
[PCI_passthrough_via_OVMF - ArchWiki](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF)\
[vfio_dma_map error when passthrough GPU using libvirt - StackOverflow](https://stackoverflow.com/questions/39187619/vfio-dma-map-error-when-passthrough-gpu-using-libvirt)\
[Non-root GPU passthrough setup](https://www.evonide.com/non-root-gpu-passthrough-setup/)

---

If you've bound the GPU to vfio-pci but not yet attached it to virtual machine
and boot, you may find the GPU's fans are always spinning, this is because
vfio-pci is lacking the ability of precise fan control, normally this work is
leaving to ventor's driver to handle, which need you to keep the virtual machine
running. If you don't want the Windows VM to occupy resources all
the time, you could create another lightweight linux virtual machine with GPU
driver installed, attach the GPU to it, and keep it running.

Ref: [GPU fans are always spinning even VM is not running - Reddit](https://www.reddit.com/r/VFIO/comments/1ik8f6z/gpu_blasting_fan_and_heating_up_even_when_vm_is/)

## Looking Glass

[Looking Glass](https://looking-glass.io/) offers a nearly native performance
display screen for virtual machine with GPU passthrouth.

For the most part of installation and configuration, you can refer to the
[official documentation](https://looking-glass.io/docs/), I will only fill
some gaps in this section.

Give regular user permission to access KVMFR device via
`/etc/udev/rules.d/50-uaccess.rules`:

```
SUBSYSTEM=="kvmfr", MODE="0660", TAG+="uaccess"
```

Ref: [Udev Rules](#udev-rules)

If you want to create multiple KVMFR devices for multiple virtual machines,
then assign multiple values for the kernel module parameter, seperated with comma,
in `/etc/modprobe.d/kvmfr.conf`:

```
options kvmfr static_size_mb=32,32,32
```

The result will be `/dev/kvmfr0`, `/dev/kvmfr1`, `/dev/kvmfr2`.

Load KVMFR module automatically at boot via systemd:

```
(root)# echo "kvmfr" > /etc/modules-load.d/kvmfr.conf
```

Ref: [Kernel_module#systemd](https://wiki.archlinux.org/title/Kernel_module#systemd)

When enabling SPICE, it is recommended to use UNIX socket instead of TCP port,
since it's better for script automation, no need to maintain unique port for every
virtual machine specifically:

```
(user)$ qemu-system-x86 \
    ... \
    -spice unix=on,addr=/data/vms/win11/spice.sock,disable-ticketing=on
```

Ref: [Spice User Manual](https://www.spice-space.org/spice-user-manual.html)

VirtIO input devices for keyboard and mouse:

```
(user)$ qemu-system-x86 \
    ... \
    -device virtio-keyboard -device virtio-mouse
```

Start `looking-glass-client` with SPICE UNIX socket file:

```
(user)$ looking-glass-client -f /dev/kvmfr0 -c /data/vms/win11/spice.sock -p 0
```

## Udev Rules

"When a kernel driver initializes a device, the default state of the device node is
to be owned by root:root, with permissions 600. This makes devices inaccessible to
regular users unless the driver changes the default, or a udev rule in userspace
changes the permissions."

"The modern recommended approach for systemd systems is to use a MODE of 660 to
let the group use the device, and then attach a TAG named uaccess. This special
tag makes udev apply a dynamic user ACL to the device node, which coordinates with
systemd-logind to make the device usable to logged-in users."

Allow regular user to use all USB devices,
create `/etc/udev/rules.d/50-uaccess.rules` with:

```
SUBSYSTEM=="usb", MODE="0660", TAG+="uaccess"
```

"Note: For any rule adding the `uaccess` tag to be effective, the name of the file it is defined in
[has to lexically precede](https://github.com/systemd/systemd/issues/4288#issuecomment-348166161)
`/usr/lib/udev/rules.d/73-seat-late.rules`"

Apply new rules:

```
(root)# udevadm control -R && udevadm trigger
```

Ref: [Udev#Allowing regular users to use devices](https://wiki.archlinux.org/title/Udev#Allowing_regular_users_to_use_devices)
, [Udev#Loading new rules](https://wiki.archlinux.org/title/Udev#Loading_new_rules)

## Hyper-V Enlightenments

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

Ref: [QEMU#Improve virtual machine performance](https://wiki.archlinux.org/title/QEMU#Improve_virtual_machine_performance)
, [Hyper-V Enlightenments](https://www.qemu.org/docs/master/system/i386/hyperv.html)

## Windows Localtime

"By default, Windows assumes the firmware clock is set to local time,
but this is usually not the case when using QEMU. To remedy this you can
[configure Windows to use UTC](https://wiki.archlinux.org/title/System_time#UTC_in_Microsoft_Windows)
after the installation, or you can set the virtual clock to
localtime by adding -rtc base=localtime to your command line."

Ref: [QEMU#Time_standard](https://wiki.archlinux.org/title/QEMU#Time_standard)

## Boot From Physical Disk

To boot from physical disk, only one thing need to do, which is configuring udev rules
for that disk device, give it normal user access permission, similar as section
[Udev Rules](#udev-rules).

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
append to `/etc/udev/rules.d/50-uaccess.rules`:

```
KERNEL=="sd*", SUBSYSTEM=="block", SUBSYSTEMS=="scsi", \
ATTRS{model}=="SSD 32GB*", ATTRS{vendor}=="ATA*", \
MODE="0660", TAG+="uaccess"
```

Apply new rules:

```
(root)# udevadm control -R && udevadm trigger
```

Boot qemu with raw format:

```
$ qemu-system-x86_64 \
    ... \
    -drive file=/dev/sdb,if=none,id=disk0,format=raw \
    -device virtio-blk-pci,drive=disk0,bootindex=1
```

Ref: [Udev#udev rule example](https://wiki.archlinux.org/title/Udev#udev_rule_example)

