+++
title       = "Arch Linux Post Install Based On Sway"
lastmod     = 2025-04-12T10:29:00+08:00
date        = 2024-11-24
showSummary = true
showTOC     = true
weight      = 1000
+++

Build the exact system that fit my needs.

<!--more-->

The goal is to keep it as minimal as possible, with essential functions.

For basic system installation, refer to my prev post:
[Arch Linux Install: LUKS + Btrfs + Systemd-boot](/posts/archlinux-install-luks-btrfs-systemd-boot/)

Upgrade system first before installing any packages.\
Ref: [System maintenance#Avoid certain pacman commands](https://wiki.archlinux.org/title/System_maintenance#Avoid_certain_pacman_commands)

```
$ sudo pacman -Syu
```

## Sway

Ref: [Sway](https://wiki.archlinux.org/title/Sway)
, [XDG Desktop Portal](https://wiki.archlinux.org/title/XDG_Desktop_Portal)
, [XDG user directories](https://wiki.archlinux.org/title/XDG_user_directories)
, [Desktop notifications](https://wiki.archlinux.org/title/Desktop_notifications)

```
$ sudo pacman -S \
    sway swaylock swayidle swaybg xorg-xwayland wl-clipboard \
    xdg-desktop-portal-gtk xdg-desktop-portal-wlr xdg-user-dirs \
    wmenu alacritty mako wob grim sway-contrib kanshi
```

[alacritty](https://alacritty.org): terminal emulator, mako: desktop notification.\
[wob](https://github.com/francma/wob): indicator bar for volume or brightness, ref:
[Sway#Graphical indicator bars](https://wiki.archlinux.org/title/Sway#Graphical_indicator_bars)
, [mywob](https://gitlab.com/wef/dotfiles/-/blob/master/bin/mywob)\
[sway-contrib](https://github.com/OctopusET/sway-contrib): area screenshot and window screenshot;
grim: screenshot\
[kanshi](https://gitlab.freedesktop.org/emersion/kanshi): dynamic output configuration, ref:
[Kanshi](https://wiki.archlinux.org/title/Kanshi)
, [kanshi(5)](https://man.archlinux.org/man/kanshi.5.en)

Initialize sway config file:

```
$ mkdir -p ~/.config/sway
$ sudo cp /etc/sway/config ~/.config/sway/
$ sudo chown $USER:$USER ~/.config/sway/config
```

The default config is a good start point, it has elaborate comments.
Then you may read [i3 User’s Guide](https://i3wm.org/docs/userguide.html) for more details.

## Keymap

Ref: [Sway#Keymap](https://wiki.archlinux.org/title/Sway#Keymap)

Remap CapsLock to Ctrl, swap Alt with Win, and enable NumLock.\
Edit `"~/.config/sway/config"` with:

```
input type:keyboard {
    xkb_options 'ctrl:nocaps,altwin:swap_alt_win'
    xkb_numlock enabled
}
```

The position of left Alt key is the best for modifier key,
but some applications have useful default shortcuts combined with Alt key,
such as `Alt+b` `Alt+f` in bash for jumping backward and forward word by word.
So I swap Alt with Win then set Win as the main modifier key.

For keybinding configs,
Use [wev](https://archlinux.org/packages/?name=wev) to detect key names.

## Input Method

Ref: [Fcitx5](https://wiki.archlinux.org/title/Fcitx5)
, [Using Fcitx 5 on Wayland](https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland)
, [sway(5)](https://man.archlinux.org/man/sway.5.en)

```
$ sudo pacman -S fcitx5-im fcitx5-rime
```

Edit `".bashrc"` with:

```
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
```

Autostart with sway, edit `"~/.config/sway/config"` with:

```
exec fcitx5 -d -r
```

Fix fcitx5 not working for chromium on wayland,
enter `"chrome://flags"` from chromium address bar, search for `"wayland"`, edit:

```
Preferred Ozone platform: Auto
Wayland text-input-v3: Enabled
```

## PipeWire

Ref: [Advanced Linux Sound Architecture](https://wiki.archlinux.org/title/Advanced_Linux_Sound_Architecture)
, [PipeWire](https://wiki.archlinux.org/title/PipeWire)

```
# pacstrap /mnt alsa-utils \
    pipewire wireplumber \
    pipewire-alsa pipewire-pulse pipewire-jack lib32-pipewire
```

## Volume Control

Ref: [No sound in mpv vlc but works in web browser](https://wiki.archlinux.org/title/PipeWire#No_sound_in_mpv,_vlc,_totem,_but_sound_works_in_web_browser_and_GNOME_speaker_test)

```
$ sudo pacman -S pavucontrol
```

## File Manager, Reader

Ref: [PCManFM](https://wiki.archlinux.org/title/PCManFM)
, [GVFS](https://wiki.archlinux.org/title/File_manager_functionality#Mounting)

```
$ sudo pacman -S \
    pcmanfm-qt lxqt-archiver p7zip libarchive \
    gvfs gvfs-mtp gvfs-afc \
    zathura zathura-pdf-mupdf tesseract-data-eng tesseract-data-chi_sim \
    imv mpv chromium
```

[zathura](https://pwmt.org/projects/zathura/documentation/) pdf,epub viewer,
ref: [zathura - archwiki](https://wiki.archlinux.org/title/Zathura)
, [tesseract data files](https://tesseract-ocr.github.io/tessdoc/Data-Files-in-different-versions.html)\
zathura tips: to revert color, use `ctrl-r` or `:set recolor <true|false>`\
[imv](https://man.archlinux.org/man/imv.1.en) image viewer\
[mpv](https://wiki.archlinux.org/title/Mpv) video/audio player,
also image viewer via configuration
[mpv-image-viewer](https://github.com/occivink/mpv-image-viewer)

Setting default applications: [XDG MIME Applications#mimeapps.list](https://wiki.archlinux.org/title/XDG_MIME_Applications#mimeapps.list)
, [Zathura#Make zathura the default pdf viewer](https://wiki.archlinux.org/title/Zathura#Make_zathura_the_default_pdf_viewer)
, [Desktop entries](https://wiki.archlinux.org/title/Desktop_entries)

The fallback Qt theme is not looking good, for better appearance, check section [Qt Theme](#qt-theme).

Following settings are for GTK based file managers, like Thunar and Nemo.

Disable GTK recent files. Ref: [gsettings](https://man.archlinux.org/man/gsettings.1)

```
$ gsettings set org.cinnamon.desktop.privacy remember-recent-files false
$ rm ~/.local/share/recently-used.xbel
$ ln -s /dev/null ~/.local/share/recently-used.xbel
```

Change the default terminal emulator for GTK based desktop

```
$ gsettings set org.cinnamon.desktop.default-applications.terminal exec alacritty
```

## Polkit

Tools like [ventoy](https://www.ventoy.net/) need polkit to evaluate privilege.\
Ref: [polkit](https://wiki.archlinux.org/title/Polkit)

```
$ sudo pacman -S polkit lxqt-policykit
```

Autostart with sway, edit `"~/.config/sway/config"` with:

```
exec lxqt-policykit-agent
```

## Appearance

Necessary appearance settings.

### Fonts

```
# pacstrap /mnt noto-fonts noto-fonts-cjk noto-fonts-emoji \
    hicolor-icon-theme
```

Adjust fallback fonts order, this is for fixing wierd looking of some Chinese characters,
such as "复制".\
Ref: [Font configuration#Fontconfig configuration](https://wiki.archlinux.org/title/Font_configuration#Fontconfig_configuration)
, [Font configuration#Alias](https://wiki.archlinux.org/title/Font_configuration#Alias)

Create `"/etc/fonts/local.conf"` with:

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

### Icon Theme

Ref: [Icons](https://wiki.archlinux.org/title/Icons)

```
$ sudo pacman -S papirus-icon-theme
```

Change default GTK icon theme:

```
$ ls /usr/share/icons
$ gsettings set org.gnome.desktop.interface icon-theme Papirus
```

Ref: [GTK#Basic theme configuration](https://wiki.archlinux.org/title/GTK#Basic_theme_configuration)
, [GTK 3 settings on Wayland](https://github.com/swaywm/sway/wiki/GTK-3-settings-on-Wayland)

For Qt settings check section [Qt Theme](#qt-theme).

### Qt Theme

Install `qt6ct` and set environment variables, then restart sway:

```
$ sudo pacman -S qt6ct
$ echo "export QT_QPA_PLATFORMTHEME=qt6ct" >> ~/.bashrc
```

Ref: [Configuration of Qt 5/6 applications under environments other than KDE Plasma](https://wiki.archlinux.org/title/Qt#Configuration_of_Qt_5/6_applications_under_environments_other_than_KDE_Plasma)
, [Not showing functional icons](https://github.com/lxqt/pavucontrol-qt/issues/126)

Not recommending the `breeze` theme, the package will install lots of irrelevant KDE components,
which is annoying, this is the most reason I don't like KDE stuff.

### GTK Dark Theme

```
$ sudo pacman -S gnome-themes-extra
$ ls /usr/share/themes
$ gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark
```

### Cursor Size

Change cursor size by setting cursor theme, edit `"~/.config/sway/config"` with:

```
seat seat0 xcursor_theme default 32
```

Ref: [Sway#Change cursor theme and size](https://wiki.archlinux.org/title/Sway#Change_cursor_theme_and_size)

## GPU

AMD. Ref: [AMDGPU#Installation](https://wiki.archlinux.org/title/AMDGPU#Installation)

```
$ sudo pacman -S lib32-mesa vulkan-radeon lib32-vulkan-radeon
```

Intel. Ref: [Intel graphics#Installation](https://wiki.archlinux.org/title/Intel_graphics#Installation)

```
$ sudo pacman -S lib32-mesa vulkan-intel lib32-vulkan-intel
```

Hardware Video Acceleration.
Ref: [Hardware video acceleration](https://wiki.archlinux.org/title/Hardware_video_acceleration)

Alder Lake:

```
$ sudo pacman -S intel-media-driver
```

## Bluetooth

Ref: [Bluetooth](https://wiki.archlinux.org/title/Bluetooth)

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

Troubleshooting:\
Reboot computer when this error occurred:
[bluetoothctl: No default controller available](https://wiki.archlinux.org/title/Bluetooth#bluetoothctl:_No_default_controller_available)

## Printer

Install cups packages:

```
$ sudo pacman -S cups cups-pdf
$ sudo systemctl enable --now cups
```

Install printer driver if needed, for example:

```
$ yay -S brlaser
```

Ref: [AUR helpers](https://wiki.archlinux.org/title/AUR_helpers)
, [yay](https://github.com/Jguer/yay)

The CUPS server can be fully administered through the web interface, and there's
documentation for adding printer
[http://localhost:631/help/admin.html](http://localhost:631/help/admin.html).

Ref: [CUPS](https://wiki.archlinux.org/title/CUPS)

