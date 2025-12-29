+++
title       = 'Linux Post Installation: Desktop Preparation'
subtitle    = ''
lastmod     = '2025-11-30'
date        = '2025-11-26'
tags        = []
showSummary = true
showTOC     = true
weight      = 1000
+++

Essential preparation before desktop components getting involved.

<!--more-->

## Series Index

1. [Linux Bootstrap Installation](/posts/linux-bootstrap-installation/)
2. [Linux A/B System Updates via BTRFS Snapshot](/posts/linux-ab-system-updates-via-btrfs-snapshot/)
3. Linux Post Installation: Desktop Preparation
4. [Linux Desktop: Sway, Labwc, GUI Apps](/posts/linux-desktop-sway-labwc-gui-apps/)

## Preface

This guide is based on Arch, but could also work for Debian/Ubuntu and Fedora.
I'm trying my best to make it distro irrelevant, since I don't like to be bound
to any specific platform in any form, always maintaining the ability for transition.

## Default Editor

```
(root)# echo "export EDITOR=/usr/bin/nvim" > /etc/profile.d/default-editor.sh
```

You could replace `nvim` with whatever you like.

## Console Fonts

Install package `terminus-fonts` (Arch, Fedora) or `fonts-terminus` (Debian).

```
(root)# echo "FONT=ter-132b" >> /etc/vconsole.conf
```

Full font list is under `/usr/share/kbd/consolefonts/`, use `setfont <font_name>`
command to test.

Ref: [Linux_console#Fonts](https://wiki.archlinux.org/title/Linux_console#Fonts)

## Console Caps Ctrl

Remap `CapsLock` to `Ctrl` for console.

```
(root)# cd /usr/share/kbd/keymaps/i386/qwerty
(root)# gzip -dc < us.map.gz > usa.map
(root)# sed -i '/^keycode[[:space:]]58/c\keycode 58 = Control' usa.map
(root)# echo "KEYMAP=usa" >> /etc/vconsole.conf
```

Ref: [Linux_console/Keyboard_configuration#Creating_a_custom_keymap](https://wiki.archlinux.org/title/Linux_console/Keyboard_configuration#Creating_a_custom_keymap)

## Disable Watchdogs

This setting is for
[improving performance](https://wiki.archlinux.org/title/Improving_performance#Watchdogs).

Check for a hardware watchdog module:

```
(root)# lsmod | grep wdt
```

Add to
[kernel module blacklist](https://wiki.archlinux.org/title/Kernel_module#Blacklisting):

```
(root)# cat > /etc/modprobe.d/nowatchdogs.conf << EOB
blacklist iTCO_wdt
blacklist sp5100_tco
blacklist intel_oc_wdt
EOB
```

## PipeWire

Install [PipeWire](https://wiki.archlinux.org/title/PipeWire) related packages:

Arch, Debian: `pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber`\
Fedora: `pipewire pipewire-alsa pipewire-pulseaudio pipewire-plugin-jack wireplumber`

## Bluetooth

Install [Bluetooth](https://wiki.archlinux.org/title/Bluetooth) related packages:

Arch: `bluez bluez-utils`\
Fedora, Debian: `bluez bluez-tools`

Enable systemd service: `systemctl enable --now bluetooth.service`.

## Printer

Install [CUPS](https://wiki.archlinux.org/title/CUPS) related packages:

Arch, Fedora: `cups cups-pdf`\
Debian: `cups printer-driver-cups-pdf`

Enable systemd service: `systemctl enable --now cups.service`.

The CUPS server can be fully administered through the web interface,
and there’s documentation for adding printer
[http://localhost:631/help/admin.html](http://localhost:631/help/admin.html).

## GPU Drivers

![Linus Torvalds Fuck You Nvidia](/images/linus-torvalds-fuck-you-nvidia.webp)

I only use
[AMD GPU](https://wiki.archlinux.org/title/AMDGPU)
and
[Intel GPU](https://wiki.archlinux.org/title/Intel_graphics)
on Linux for the well known reasons.

Install `mesa` and `vulkan` related packages:

Arch AMD: `mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon`\
Debian, Fedora AMD: `mesa mesa-vulkan-drivers`

Arch Intel: `mesa lib32-mesa vulkan-intel lib32-vulkan-intel intel-media-driver`\
Debian Intel: `mesa mesa-vulkan-drivers intel-media-va-driver`\
Fedora Intel: `mesa mesa-vulkan-drivers libva-intel-media-driver`

## Regular User

Install [xdg-user-dirs](https://wiki.archlinux.org/title/XDG_user_directories)
package, it's for managing well known user directories
e.g. Desktop, Documents, Downloads etc.

Create regular user:

```
(root)# useradd -m -G wheel -s /bin/bash user1
(root)# passwd user1
```

## GUI Fonts

Install Noto fonts related packages:

Arch: `noto-fonts noto-fonts-cjk noto-fonts-emoji`\
Debian:
```
fonts-noto fonts-noto-extra fonts-noto-mono
fonts-noto-cjk fonts-noto-cjk-extra
fonts-noto-color-emoji
fonts-noto-ui-core fonts-noto-ui-extra fonts-noto-unhinted
```
Fedora:
```
google-noto-fonts-all
google-noto-sans-cjk-fonts google-noto-serif-cjk-fonts
google-noto-emoji-fonts
```

The default lookup order for CJK fonts would pick wrong characters in some cases,
such as “复” in chinese word “复制”.
To fix this, adjust fallback font order by creating `/etc/fonts/local.conf` with:

```
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
<alias>
    <family>sans-serif</family>
    <prefer>
        <family>Noto Sans</family>
        <family>Noto Sans CJK SC</family>
        <family>Noto Sans CJK TC</family>
        <family>Noto Sans CJK HK</family>
        <family>Noto Sans CJK JP</family>
        <family>Noto Sans CJK KR</family>
    </prefer>
</alias>
<alias>
    <family>serif</family>
    <prefer>
        <family>Noto Serif</family>
        <family>Noto Serif CJK SC</family>
        <family>Noto Serif CJK TC</family>
        <family>Noto Serif CJK HK</family>
        <family>Noto Serif CJK JP</family>
        <family>Noto Serif CJK KR</family>
    </prefer>
</alias>
<alias>
    <family>monospace</family>
    <prefer>
        <family>Noto Sans Mono</family>
        <family>Noto Sans Mono CJK SC</family>
        <family>Noto Sans Mono CJK TC</family>
        <family>Noto Sans Mono CJK HK</family>
        <family>Noto Sans Mono CJK JP</family>
        <family>Noto Sans Mono CJK KR</family>
    </prefer>
</alias>
</fontconfig>
```

Later you could create `~/.config/fontconfig/fonts.conf` with same format under
your user home directory to overwrite this configuration,
replace with custom fonts under `~/.local/share/fonts`.

Ref: [Font configuration#Fontconfig configuration](https://wiki.archlinux.org/title/Font_configuration#Fontconfig_configuration)
, [Font configuration#Alias](https://wiki.archlinux.org/title/Font_configuration#Alias)

## Icon Theme

Install
[icons](https://wiki.archlinux.org/title/Icons)
related packages: `hicolor-icon-theme papirus-icon-theme`.

`wheel` is the superuser group for sudo in Arch and Fedora, for Debian,
it's named `sudo`.

## GTK Theme

Set GTK icon theme

```
(user)$ ls /usr/share/icons
(user)$ gsettings set org.gnome.desktop.interface icon-theme Papirus
```

For dark GTK theme, install package `gnome-themes-extra`, then:

```
(user)$ ls /usr/share/themes
# GTK3
(user)$ gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark
# GTK4
(user)$ gsettings set org.gnome.desktop.interface color-scheme prefer-dark/default
```

Ref: [GTK#Basic theme configuration](https://wiki.archlinux.org/title/GTK#Basic_theme_configuration)
, [GTK 3 settings on Wayland](https://github.com/swaywm/sway/wiki/GTK-3-settings-on-Wayland)

## Qt Theme

IMHO, if you're not intended to use KDE desktop environment, then avoid choosing
KDE apps, since they are tightly coupled with the KDE suite, heavily
rely on KDE's components, lots of dependencies would be installed even
for a very simple app, which is annoying. LXQt apps are in a similar situation.

The original
[qt6ct](https://github.com/trialuser02/qt6ct)
is archived, although there is a
[successor](https://www.opencode.net/trialuser/qt6ct), I decided not dealing with
KDE apps anymore. For other independent Qt apps, they usually work well by default,
no need tools like qt5ct/qt6ct get involved.

