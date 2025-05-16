+++
aliases     = ["/posts/archlinux-post-install-sway", "/posts/archlinux-post-install-based-on-sway"]
title       = "Arch Linux Post Install: Wayland and Others"
lastmod     = 2025-04-23T14:06:00+08:00
date        = 2024-11-24
showSummary = true
showTOC     = true
weight      = 1000
+++

Build a minimal workstation with essential components, no ricing.

<!--more-->

## Prerequisite

For basic system installation, refer to my prev post:
[Arch Linux Install: LUKS + Btrfs + Systemd-boot](/posts/archlinux-install-luks-btrfs-systemd-boot/)

Upgrade system first before installing any packages.\
Ref: [System maintenance#Avoid certain pacman commands](https://wiki.archlinux.org/title/System_maintenance#Avoid_certain_pacman_commands)

```
$ sudo pacman -Syu
```

## Wayland Compositor

I prefer wayland GUI environment since its ecosystem is mature enough.\
I prefer wayland compositors since I'm an experienced user who thinks desktop environments are bloat.\
I use [sway](https://swaywm.org) on my host machine, and use [labwc](labwc.github.io)
for virtual machine.

Packages for sway, labwc and other essential components:

```
$ sudo pacman -S \
    sway swaylock swayidle swaybg labwc \
    xorg-xwayland wl-clipboard \
    xdg-desktop-portal-gtk xdg-desktop-portal-wlr xdg-user-dirs \
    wmenu alacritty mako wob grim sway-contrib kanshi wev
```

xdg-desktop-portal-gtk : necessary component for e.g. file chooser.\
xdg-desktop-portal-wlr : necessary component for e.g. screenshot.\
[XDG user directories](https://wiki.archlinux.org/title/XDG_user_directories) :
manage well known user directories e.g. Desktop, Documents, Downloads etc.\
[wl-clipboard](https://github.com/bugaevc/wl-clipboard) : wayland clipboard utilities.\
[wmenu](https://codeberg.org/adnano/wmenu) : menu for running commands, launching apps.\
[alacritty](https://alacritty.org) : terminal emulator.\
[mako](https://github.com/emersion/mako) : desktop notification.\
[wob](https://github.com/francma/wob) : indicator bar for volume or brightness.\
[grim](https://gitlab.freedesktop.org/emersion/grim) screenshot tool for wayland.\
[sway-contrib](https://github.com/OctopusET/sway-contrib) : grim helper for partial screenshot.\
[kanshi](https://gitlab.freedesktop.org/emersion/kanshi): dynamic output configuration.\
[wev](https://git.sr.ht/~sircmpwn/wev) : detect key name, for configuring keybindings.

Ref: [Sway](https://wiki.archlinux.org/title/Sway)
, [Labwc](https://wiki.archlinux.org/title/Labwc)
, [XDG Desktop Portal](https://wiki.archlinux.org/title/XDG_Desktop_Portal)

Here is my configurations for sway and labwc: [wlrc](https://github.com/undus5/wlrc)
, feel free to download and test.

## Appearance

Not ricing, but fixing some missing configurations.

### CJK Fonts

```
$ sudo pacman -S noto-fonts noto-fonts-cjk noto-fonts-emoji
```

The default lookup order for CJK fonts has a little problem,
picking wrong characters in some cases, such as "复" in chinese word "复制".

Adjust fallback fonts order to fix the problem,
create `/etc/fonts/local.conf` with:

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

Later you could create `~/.config/fontconfig/fonts.conf` with same format to
overwrite this configuration, replace with custom fonts under `~/.local/share/fonts`
for example.

Ref: [Font configuration#Fontconfig configuration](https://wiki.archlinux.org/title/Font_configuration#Fontconfig_configuration)
, [Font configuration#Alias](https://wiki.archlinux.org/title/Font_configuration#Alias)

### Icon Theme

Icon theme is an essential component,
[Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme)
is a good one.

"It is recommended to install the `hicolor-icon-theme` package as many programs
will deposit their icons in `/usr/share/icons/hicolor/` and most other icon themes
will inherit icons from the Hicolor icon theme"

```
$ sudo pacman -S papirus-icon-theme hicolor-icon-theme
```

Ref: [Icons](https://wiki.archlinux.org/title/Icons)

### GTK Theme

Set GTK icon theme

```
$ ls /usr/share/icons
$ gsettings set org.gnome.desktop.interface icon-theme Papirus
```

Set GTK dark theme

```
$ sudo pacman -S gnome-themes-extra
$ ls /usr/share/themes
$ gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark
```

Ref: [GTK#Basic theme configuration](https://wiki.archlinux.org/title/GTK#Basic_theme_configuration)
, [GTK 3 settings on Wayland](https://github.com/swaywm/sway/wiki/GTK-3-settings-on-Wayland)

For Qt settings check following section [Qt Theme](#qt-theme).

### Qt Theme

Without proper settings, Qt apps is not looking good, also may not showing icons correctly.

Install `qt6ct` and set environment variables, then restart wayland compositor:

```
$ sudo pacman -S qt6ct
$ echo "export QT_QPA_PLATFORMTHEME=qt6ct" >> ~/.bashrc
```

Not recommending the `breeze` theme, the package is highly dependent on the KDE framework, 
would install lots of irrelevant KDE components, which is annoying,
this is the most reason I don't like KDE stuff.

Ref: [Configuration of Qt 5/6 applications under environments other than KDE Plasma](https://wiki.archlinux.org/title/Qt#Configuration_of_Qt_5/6_applications_under_environments_other_than_KDE_Plasma)
, [Not showing functional icons](https://github.com/lxqt/pavucontrol-qt/issues/126)

## Sound System

### PipeWire

```
$ sudo pacman -S alsa-utils \
    pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber lib32-pipewire
```

Ref: [Advanced Linux Sound Architecture](https://wiki.archlinux.org/title/Advanced_Linux_Sound_Architecture)
, [PipeWire](https://wiki.archlinux.org/title/PipeWire)

### Volume Control

```
$ sudo pacman -S pavucontrol
```

Ref: [No sound in mpv vlc but works in web browser](https://wiki.archlinux.org/title/PipeWire#No_sound_in_mpv,_vlc,_totem,_but_sound_works_in_web_browser_and_GNOME_speaker_test)

## File Manager, Reader

```
$ sudo pacman -S \
    pcmanfm-qt lxqt-archiver p7zip libarchive \
    gvfs gvfs-mtp gvfs-afc \
    zathura zathura-pdf-mupdf tesseract-data-eng \
    imv mpv chromium
```

[PCManFM](https://wiki.archlinux.org/title/PCManFM) : file manager.\
[GVFS](https://wiki.archlinux.org/title/File_manager_functionality#Mounting) :
provides mounting and trash functionality.\
[Zathura](https://pwmt.org/projects/zathura/documentation/) : pdf/epub viewer.\
[Tesseract](https://tesseract-ocr.github.io/tessdoc/) : zathura dependency, OCR engine.\
[imv](https://sr.ht/~exec64/imv/) : image viewer.\
[mpv](https://mpv.io/) : video/audio player.\
[Chromium](https://wiki.archlinux.org/title/Chromium) : web browser.

## Polkit

Tools like [Ventoy](https://www.ventoy.net/) need polkit to evaluate privilege.\

```
$ sudo pacman -S polkit lxqt-policykit
```

Autostart with sway, edit `~/.config/sway/config` with:

```
exec lxqt-policykit-agent
```

Ref: [polkit](https://wiki.archlinux.org/title/Polkit)

## Input Method

I use [Fcitx5](https://fcitx-im.org/wiki/Fcitx_5) and
[RIME](https://rime.im) to input chinese characters.
Here is my RIME config for Wubi86 : [rimerc](https://github.com/undus5/rimerc).

```
$ sudo pacman -S fcitx5 fcitx5-qt fcitx5-configtool fcitx5-rime
```

Edit `.bashrc` with:

```
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
```

Autostart with sway, edit `~/.config/sway/config` with:

```
exec fcitx5 -d -r
```

Fix fcitx5 not working for Chromium on wayland,
enter `chrome://flags` from Chromium address bar, search for `wayland`, edit:

```
Preferred Ozone platform: Auto
Wayland text-input-v3: Enabled
```

Ref: [Fcitx5](https://wiki.archlinux.org/title/Fcitx5)
, [Using Fcitx 5 on Wayland](https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland)

## GPU Drivers

For [AMDGPU#Installation](https://wiki.archlinux.org/title/AMDGPU#Installation)

```
$ sudo pacman -S vulkan-radeon lib32-vulkan-radeon lib32-mesa
```

For [Intel graphics#Installation](https://wiki.archlinux.org/title/Intel_graphics#Installation)

```
$ sudo pacman -S vulkan-intel lib32-vulkan-intel lib32-mesa
```

For [Hardware video acceleration](https://wiki.archlinux.org/title/Hardware_video_acceleration)

Intel Alder Lake:

```
$ sudo pacman -S intel-media-driver
```

## Peripheral Device

### Bluetooth

```
$ sudo pacman -S bluez bluez-utils
$ sudo systemctl enable --now bluetooth
```

Pairing

```
$ bluetoothctl
[bluetoothctl]# scan on
[bluetoothctl]# pair <MAC_ADDRESS> (tab completion works)
```

Troubleshooting:
Reboot computer when this error occurred:
[bluetoothctl: No default controller available](https://wiki.archlinux.org/title/Bluetooth#bluetoothctl:_No_default_controller_available)

Ref: [Bluetooth](https://wiki.archlinux.org/title/Bluetooth)

### Printer

```
$ sudo pacman -S cups cups-pdf
$ sudo systemctl enable --now cups
```

The CUPS server can be fully administered through the web interface, and there's
documentation for adding printer
[http://localhost:631/help/admin.html](http://localhost:631/help/admin.html).

Ref: [CUPS](https://wiki.archlinux.org/title/CUPS)

Install printer driver if needed, in my case is `brlaser` package from AUR:

```
$ sudo pacman -S base-devel
$ git clone https://aur.archlinux.org/brlaser.git ~/
$ cd ~/brlaser
$ makepkg -sic
```

Ref: [Arch User Repository](https://wiki.archlinux.org/title/Arch_User_Repository)

