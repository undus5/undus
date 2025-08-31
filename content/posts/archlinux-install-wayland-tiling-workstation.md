+++
title       = "Arch Linux Install: Wayland Tiling Workstation"
lastmod     = 2025-08-31
date        = 2024-11-24
showSummary = true
showTOC     = true
weight      = 1000
+++

Build a compact workstation with essential components, no ricing.

<!--more-->

## Prerequisite

For basic system installation, refer to my prev post:
[Arch Linux Install: LUKS + Btrfs + Systemd-boot](/posts/archlinux-install-luks-btrfs-systemd-boot/)

Upgrade system first before installing any packages.\
Ref: [System maintenance#Avoid certain pacman commands](https://wiki.archlinux.org/title/System_maintenance#Avoid_certain_pacman_commands)

```
#(root) pacman -Syu
```

## Wayland

I prefer wayland GUI environment since its ecosystem is mature enough.\
I prefer wayland compositors since I'm an experienced user who thinks desktop environments are bloat.\
I use [sway](https://swaywm.org) on my host machine, and use [labwc](labwc.github.io)
for virtual machine.

### Sway & Labwc

Packages for [Sway](https://wiki.archlinux.org/title/Sway),
[Labwc](https://wiki.archlinux.org/title/Labwc) and other essential components:

```
#(root) pacman -S \
    sway swaylock swayidle swaybg labwc \
    xorg-xwayland wl-clipboard \
    xdg-desktop-portal-wlr xdg-desktop-portal-gtk xdg-user-dirs \
    wmenu mako wob grim sway-contrib kanshi wev
```

[xdg-desktop-portal](https://wiki.archlinux.org/title/XDG_Desktop_Portal):\
xdg-desktop-portal-gtk : necessary component for e.g. file chooser.\
xdg-desktop-portal-wlr : necessary component for e.g. screenshot.\
[xdg-user-dirs](https://wiki.archlinux.org/title/XDG_user_directories):
manage well known user directories e.g. Desktop, Documents, Downloads etc.\
[wl-clipboard](https://github.com/bugaevc/wl-clipboard) : necessary for ctrl-c ctrl-v function.\
[wmenu](https://codeberg.org/adnano/wmenu) : menu for launching apps and running commands.\
[mako](https://github.com/emersion/mako) : desktop notification.\
[wob](https://github.com/francma/wob) : indicator bar for volume or brightness.\
[grim](https://gitlab.freedesktop.org/emersion/grim) screenshot tool for wayland.\
[sway-contrib](https://github.com/OctopusET/sway-contrib) : grim helper for partial screenshot.\
[kanshi](https://gitlab.freedesktop.org/emersion/kanshi): dynamic output configuration.\
[wev](https://git.sr.ht/~sircmpwn/wev) : detect key name, for configuring keybindings.

Here is my configurations for sway and labwc: [wlrc](https://github.com/undus5/wlrc).

## CJK Fonts Fix

```
#(root) pacman -S noto-fonts noto-fonts-cjk noto-fonts-emoji
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

## Appearance Fix

There are some configurations need to be fixed for GUI apps.

### Icon Theme

Icon theme is an essential component,
[Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme)
is a good one.

"It is recommended to install the `hicolor-icon-theme` package as many programs
will deposit their icons in `/usr/share/icons/hicolor/` and most other icon themes
will inherit icons from the Hicolor icon theme"

```
#(root) pacman -S papirus-icon-theme hicolor-icon-theme
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
#(root) pacman -S gnome-themes-extra
$ ls /usr/share/themes
(GTK 3)
$ gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark
(GTK 4)
$ gsettings set org.gnome.desktop.interface color-scheme prefer-dark
```

Ref: [GTK#Basic theme configuration](https://wiki.archlinux.org/title/GTK#Basic_theme_configuration)
, [GTK 3 settings on Wayland](https://github.com/swaywm/sway/wiki/GTK-3-settings-on-Wayland)

For Qt settings check following section [Qt Theme](#qt-theme).

### Qt Theme

Without proper settings, Qt apps is not looking good, also may not showing icons correctly.

Install `qt6ct` and set environment variables, then restart wayland compositor:

```
#(root) pacman -S qt6ct
$ echo "export QT_QPA_PLATFORMTHEME=qt6ct" >> ~/.bashrc
```

Ref: [Configuration of Qt 5/6 applications under environments other than KDE Plasma](https://wiki.archlinux.org/title/Qt#Configuration_of_Qt_5/6_applications_under_environments_other_than_KDE_Plasma)
, [Not showing functional icons](https://github.com/lxqt/pavucontrol-qt/issues/126)

Ref: [No sound in mpv vlc but works in web browser](https://wiki.archlinux.org/title/PipeWire#No_sound_in_mpv,_vlc,_totem,_but_sound_works_in_web_browser_and_GNOME_speaker_test)

## Terminal

[Alacritty](https://alacritty.org) is a modern terminal emulator that comes with sensible defaults.

```
#(root) pacman -S alacritty
```

## File Manager

### Nautilus

Nautilus also known as [GNOME/Files](https://wiki.archlinux.org/title/GNOME/Files).


```
#(root) pacman -S \
    nautilus nautilus-image-converter gvfs gvfs-mtp gvfs-gphoto2 gvfs-afc
```

[GVFS](https://wiki.archlinux.org/title/File_manager_functionality#Mounting):
for auto mounting usb drives, mobile devices and trash functionality.\

### Dolphin

[Dolphin](https://wiki.archlinux.org/title/Dolphin) is the default file manager of KDE.

```
#(root) pacman -S dolphin
```

Change default terminal, edit `~/.config/kdeglobals` with:

```
[General]
TerminalApplication=alacritty
TerminalService=Alacritty.desktop
```

Ref: [Dolphin change default terminal](https://wiki.archlinux.org/title/Dolphin#Change_the_default_terminal_emulator)

Fix empty appliction list when right click open with:

```
#(root) pacman -S archlinux-xdg-menu

$(user) echo 'XDG_MENU_PREFIX=arch-' >> ~/.bashrc
```

When application desktop entries changed, run `kbuildsycoca6 --noincremental`.

Ref: [Dolphin cannot find applications](https://wiki.archlinux.org/title/Dolphin#Dolphin_cannot_find_applications_(when_running_under_another_window_manager))

### iOS Support

For [iOS](https://wiki.archlinux.org/title/IOS) device support, you need to install `ifuse`:

```
#(root) pacman -S ifuse
```

### Disable recent files

```
$(user) rm ~/.local/share/recently-used.xbel
$(user) ln -s /dev/null ~/.local/share/recently-used.xbel
```

## File Readers

### PDF

```
#(root) pacman -S zathura zathura-pdf-poppler tesseract-data-eng
```

[zathura](https://pwmt.org/projects/zathura/documentation/) : pdf viewer.
[tesseract](https://tesseract-ocr.github.io/tessdoc/) : zathura dependency, OCR engine.\

### Image

```
#(root) pacman -S oculante
```

[oculante](https://github.com/woelper/oculante) : image viewer.

### Video

```
#(root) pacman -S mpv
```

[mpv](https://mpv.io/) : video/audio player.

### Compression

I recommend [PeaZip](https://peazip.github.io/) as archive manager.

Install dependency first:

```
#(root) pacman -S qt6pas
```

Download peazip tarball and extract to e.g. `/data/apps/peazip`,
copy `/data/apps/peazip/res/share/batch/freedesktop_integration/peazip.desktop`
to `~/.local/share/applications/` then edit `Exec` and `Icon` path:

```
Exec=/data/apps/peazip/peazip %F
Icon=/data/apps/peazip/res/icons/peazip
```

Ref: [Desktop entries](https://wiki.archlinux.org/title/Desktop_entries)

Also recommend installing `7zip` package for file compression in command line.

## Polkit

Tools like [Ventoy](https://www.ventoy.net/) need polkit to evaluate privilege.\

```
#(root) pacman -S polkit polkit-gnome
```

Autostart with sway, edit `~/.config/sway/config` with:

```
exec /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
```

Ref: [polkit](https://wiki.archlinux.org/title/Polkit)

## Input Method

I use [Fcitx5](https://fcitx-im.org/wiki/Fcitx_5) and
[RIME](https://rime.im) to input chinese characters.
Here is my RIME config for Wubi86 : [rimerc](https://github.com/undus5/rimerc).

```
#(root) pacman -S fcitx5 fcitx5-qt fcitx5-configtool fcitx5-rime
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

## Sound System

### PipeWire

```
#(root) pacman -S \
    alsa-utils \
    pipewire pipewire-alsa pipewire-pulse pipewire-jack lib32-pipewire \
    wireplumber
```

Ref: [Advanced Linux Sound Architecture](https://wiki.archlinux.org/title/Advanced_Linux_Sound_Architecture)
, [PipeWire](https://wiki.archlinux.org/title/PipeWire)

### Pavucontrol

Volume control tool, for switching output sound device.

```
#(root) pacman -S pavucontrol
```

## GPU Drivers

For [AMDGPU#Installation](https://wiki.archlinux.org/title/AMDGPU#Installation)

```
#(root) pacman -S vulkan-radeon lib32-vulkan-radeon lib32-mesa
```

For [Intel graphics#Installation](https://wiki.archlinux.org/title/Intel_graphics#Installation)

```
#(root) pacman -S vulkan-intel lib32-vulkan-intel lib32-mesa
```

For [Hardware video acceleration](https://wiki.archlinux.org/title/Hardware_video_acceleration)

Intel Alder Lake:

```
#(root) pacman -S intel-media-driver
```

## Peripheral Device

### Bluetooth

```
#(root) pacman -S bluez bluez-utils
#(root) systemctl enable --now bluetooth
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
#(root) pacman -S cups cups-pdf
#(root) systemctl enable --now cups
```

The CUPS server can be fully administered through the web interface, and there's
documentation for adding printer
[http://localhost:631/help/admin.html](http://localhost:631/help/admin.html).

Ref: [CUPS](https://wiki.archlinux.org/title/CUPS)

Install printer driver if needed, in my case is `brlaser` package from
[AUR](https://aur.archlinux.org/packages/brlaser):

```
#(root) pacman -S base-devel
$ git clone https://aur.archlinux.org/brlaser.git ~/
$ cd ~/brlaser
$ makepkg -sc
#(root) pacman -U brlaser-xxx.zst
```

Ref: [Arch User Repository](https://wiki.archlinux.org/title/Arch_User_Repository)

## Web Browser

### Chromium

[Chromium](https://wiki.archlinux.org/title/Chromium) : web browser.

### Brave

[Brave Browser](https://brave.com/)
([AUR](https://aur.archlinux.org/packages/brave-bin))

Disable Crypto and AI related components by default:

Create `/etc/brave/policies/managed/brave-policy.json` :

```
{
  "BraveAIChatEnabled": true,
  "BraveRewardsDisabled": true,
  "BraveVPNDisabled": 1,
  "BraveWalletDisabled": true
}
```

Visit `brave://policy` from address bar to check the effect.

Ref: [Group Policy](https://support.brave.com/hc/en-us/articles/360039248271-Group-Policy)

## QR Code

[qrencode](https://archlinux.org/packages/?q=qrencode) text to QR code image

[zbar](https://archlinux.org/packages/?q=zbar) QR code image to text

## [Useful add ons for sway](https://github.com/swaywm/sway/wiki/Useful-add-ons-for-sway)

