+++
title       = "Arch Linux Post Install: Sway"
lastmod     = 2024-11-25T16:38:00+08:00
date        = 2024-11-24
showSummary = true
showTOC     = true
weight      = 1000
+++

Build the exact system that fit my need.

<!--more-->

The goal is to keep it as minimal as possible, with essential functions.

The following instructions presume you logged in as a non-root user.

## Basic System

Refer to my prev post:
[Arch Linux with LUKS Btrfs and Systemd-boot](/posts/archlinux-with-btrfs-luks-systemd-boot/)

## Upgrade System

Upgrade first.
Ref: [System maintenance#Avoid certain pacman commands](https://wiki.archlinux.org/title/System_maintenance#Avoid_certain_pacman_commands)

```
$ sudo pacman -Syu
```

## Sway

Ref: [Sway](https://wiki.archlinux.org/title/Sway)
, [sway](https://archlinux.org/packages/?name=sway)
, [XDG Desktop Portal](https://wiki.archlinux.org/title/XDG_Desktop_Portal)
, [XDG user directories](https://wiki.archlinux.org/title/XDG_user_directories)
, [Sway#Graphical indicator bars](https://wiki.archlinux.org/title/Sway#Graphical_indicator_bars)
, [Waybar Wiki](https://github.com/Alexays/Waybar/wiki/Home)

```
$ sudo pacman -S \
    sway foot foot-terminfo wmenu swaylock swayidle swaybg sway-contrib mako xorg-xwayland \
    xdg-desktop-portal-gtk xdg-desktop-portal-wlr xdg-user-dirs \
    hicolor-icon-theme wob waybar
```

Initialize sway config file:

```
$ mkdir -p ~/.config/sway
$ sudo cp /etc/sway/config ~/.config/sway/
$ sudo chown $USER:$USER ~/.config/sway/config
```

There are elaborate comments in the default config, it's a good start point.

## Polkit

Tools like [ventoy](https://www.ventoy.net/) need polkit to evaluate privilege.\
Ref: [polkit](https://wiki.archlinux.org/title/Polkit)

```
$ sudo pacman -S \
    polkit lxqt-policykit
```

Autostart with sway, edit `"~/.config/sway/config"` with:

```
exec lxqt-policykit-agent
```

## File Manager & Viewer

Ref: [PCManFM](https://wiki.archlinux.org/title/PCManFM)
, [PCManFM#Adding custom items to the context menu](https://wiki.archlinux.org/title/PCManFM#Adding_custom_items_to_the_context_menu)

```
$ sudo pacman -S \
    pcmanfm-qt gvfs gvfs-mtp gvfs-smb gvfs-wsdd gvfs-afc gvfs-dnssd \
    lxqt-archiver p7zip libarchive \
    imv zathura foliate mpv \
    chromium
```

[lxqt-archiver](https://archlinux.org/packages/?name=lxqt-archiver)
compressing and uncompressing\
[imv](https://man.archlinux.org/man/imv.1.en) image viewer,
[zathura](https://wiki.archlinux.org/title/Zathura) pdf viewer,
[foliate](https://johnfactotum.github.io/foliate/) ebook reader\
[mpv](https://wiki.archlinux.org/title/Mpv) video/audio player,
also image viewer via configuration
[mpv-image-viewer](https://github.com/occivink/mpv-image-viewer)

Default applications: [XDG MIME Applications#mimeapps.list](https://wiki.archlinux.org/title/XDG_MIME_Applications#mimeapps.list)
, [Zathura#Make zathura the default pdf viewer](https://wiki.archlinux.org/title/Zathura#Make_zathura_the_default_pdf_viewer)
, [Desktop entries](https://wiki.archlinux.org/title/Desktop_entries)

## Volume Control

Ref: [No sound in mpv vlc but works in web browser](https://wiki.archlinux.org/title/PipeWire#No_sound_in_mpv,_vlc,_totem,_but_sound_works_in_web_browser_and_GNOME_speaker_test)

```
$ sudo pacman -S \
    pavucontrol-qt
```

## Input Method

Ref: [Fcitx5](https://wiki.archlinux.org/title/Fcitx5)
, [Using Fcitx 5 on Wayland](https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland)
, [sway(5)](https://man.archlinux.org/man/sway.5.en)

```
$ sudo pacman -S \
    fcitx5-im fcitx5-rime
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

## Inhibit Idle

Implement function like gnome-shell-extension-caffeine.

Create `"~/.config/sway/inhibit-idle.sh"` with:

```
#!/usr/bin/env bash

_label="CAFFEINE"

status() {
    swaymsg -t get_tree -r | grep -q "inhibit_idle.*true" && \
        echo "${_label}" || echo ""
}

toggle() {
    if [[ "$(status)" != "${_label}" ]]; then
        swaymsg [all] inhibit_idle open
    else
        swaymsg [all] inhibit_idle none
    fi
}

case "$1" in
    "status"|"toggle")
        $1
        ;;
    *)
        echo "Usage: $(basename $0) [status|toggle]"
        ;;
esac
```

Make it executable, then bind key combo to it in `"~/.config/sway/config"` like this:

```
bindsym $mod+z exec ~/.config/sway/inhibit-idle.sh toggle
```

Use `"~/.config/sway/inhibit-idle.sh status"` to get caffeine status,
add it to sway-bar script as an indicator.

## Appearance

Tweaking some eye candy stuff.

### Fonts

Ref: [Font configuration](https://wiki.archlinux.org/title/Font_configuration)
, [Font configuration#Alias](https://wiki.archlinux.org/title/Font_configuration#Alias)
, [Pango.FontDescription](https://docs.gtk.org/Pango/type_func.FontDescription.from_string.html#description)

Programming font:

```
$ sudo pacman -S \
    ttf-jetbrains-mono ttf-nerd-fonts-symbols
```

Sway font config, edit `"~/.config/sway/config"` with:

```
font [pango:]<font>

bar {
    font [pango:]<font>
}
```

### Icon Theme

Ref: [Icons](https://wiki.archlinux.org/title/Icons)
, [Sway#Change cursor theme and size](https://wiki.archlinux.org/title/Sway#Change_cursor_theme_and_size)
, [sway-bar(5)](https://man.archlinux.org/man/sway-bar.5.en)

```
$ sudo pacman -S \
    capitaine-cursors pop-icon-theme
```

Change default GTK icon theme:

```
$ ls /usr/share/icons
$ gsettings set org.gnome.desktop.interface Pop
```

Ref: [GTK#Basic theme configuration](https://wiki.archlinux.org/title/GTK#Basic_theme_configuration)

Set cursor theme, edit `"~/.config/sway/config"` with:

```
seat seat0 xcursor_theme capitaine-cursors 32
```

### Plymouth Theme

Collection: [adi1090x/plymouth-themes](https://github.com/adi1090x/plymouth-themes)

```
$ tar xf spinner_alt.tar.gz
$ sudo cp -r spinner_alt /usr/share/plymouth/themes/
$ sudo plymouth-set-default-theme -l
$ sudo plymouth-set-default-theme -R spinner_alt
```

Ref: [Plymouth#Install new themes](https://wiki.archlinux.org/title/Plymouth#Install_new_themes)

## Printer

[CUPS](https://wiki.archlinux.org/title/CUPS)

