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
, [XDG Desktop Portal](https://wiki.archlinux.org/title/XDG_Desktop_Portal)
, [XDG user directories](https://wiki.archlinux.org/title/XDG_user_directories)
, [Desktop_notifications](https://wiki.archlinux.org/title/Desktop_notifications)

```
$ sudo pacman -S \
    sway swaylock swayidle swaybg xorg-xwayland \
    xdg-desktop-portal-gtk xdg-desktop-portal-wlr xdg-user-dirs \
    wmenu foot foot-terminfo mako wob grim sway-contrib
```

foot: terminal emulator, mako: desktop notification.\
wob: indicator bar for volume or brightness.
Ref: [Sway#Graphical indicator bars](https://wiki.archlinux.org/title/Sway#Graphical_indicator_bars)
, [wob](https://github.com/francma/wob).\
grim: screenshot. sway-contrib: area screenshot and window screenshot.\

Initialize sway config file:

```
$ mkdir -p ~/.config/sway
$ sudo cp /etc/sway/config ~/.config/sway/
$ sudo chown $USER:$USER ~/.config/sway/config
```

The default config is a good start point, it has elaborate comments.
Then you may read [i3 User’s Guide](https://i3wm.org/docs/userguide.html) for more details.

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

## File Manager & Viewer

Ref: [PCManFM](https://wiki.archlinux.org/title/PCManFM)
, [GVFS](https://wiki.archlinux.org/title/File_manager_functionality#Mounting)

```
$ sudo pacman -S \
    pcmanfm-qt lxqt-archiver p7zip libarchive \
    gvfs gvfs-mtp gvfs-smb gvfs-wsdd gvfs-afc gvfs-dnssd \
    imv zathura foliate mpv chromium
```

[imv](https://man.archlinux.org/man/imv.1.en) image viewer,
[zathura](https://wiki.archlinux.org/title/Zathura) pdf viewer,
[foliate](https://johnfactotum.github.io/foliate/) ebook reader\
[mpv](https://wiki.archlinux.org/title/Mpv) video/audio player,
also image viewer via configuration
[mpv-image-viewer](https://github.com/occivink/mpv-image-viewer)

Default applications: [XDG MIME Applications#mimeapps.list](https://wiki.archlinux.org/title/XDG_MIME_Applications#mimeapps.list)
, [Zathura#Make zathura the default pdf viewer](https://wiki.archlinux.org/title/Zathura#Make_zathura_the_default_pdf_viewer)
, [Desktop entries](https://wiki.archlinux.org/title/Desktop_entries)

Disable GTK recent files. Ref: [gsettings](https://man.archlinux.org/man/gsettings.1)

```
$ gsettings set org.cinnamon.desktop.privacy remember-recent-files false
$ rm ~/.local/share/recently-used.xbel
$ ln -s /dev/null ~/.local/share/recently-used.xbel
```

Change the default terminal emulator for GTK based desktop

```
$ gsettings set org.cinnamon.desktop.default-applications.terminal exec foot
```

## Volume Control

Ref: [No sound in mpv vlc but works in web browser](https://wiki.archlinux.org/title/PipeWire#No_sound_in_mpv,_vlc,_totem,_but_sound_works_in_web_browser_and_GNOME_speaker_test)

```
$ sudo pacman -S pavucontrol-qt
```

Fix missing icons:

```
$ XDG_CURRENT_DESKTOP=GNOME pavucontrol-qt
```

Ref: [Configuration of Qt 5/6 applications under environments other than KDE Plasma](https://wiki.archlinux.org/title/Qt#Configuration_of_Qt_5/6_applications_under_environments_other_than_KDE_Plasma)
, [Not showing functional icons](https://github.com/lxqt/pavucontrol-qt/issues/126)

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

## Keybindings

Use [wev](https://archlinux.org/packages/?name=wev) to detect key names.

## Inhibit Idle

Implement functions like gnome-shell-extension-caffeine.

Create `"~/.config/sway/inhibit-idle.sh"` with:

```
#!/usr/bin/env bash

idle_status() {
    swaymsg -t get_tree -r | grep -q "inhibit_idle.*true" && \
        echo "CAFFEINE" || echo ""
}

idle_toggle() {
    if [[ "$(status)" != "CAFFEINE" ]]; then
        swaymsg [all] inhibit_idle open
    else
        swaymsg [all] inhibit_idle none
    fi
}

case "${1}" in
    status)
        idle_status
        ;;
    toggle)
        idle_toggle
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
add it to swaybar script as an indicator.

## Appearance

Tweaking some eye candy stuff.

### Fonts

Ref: [Font configuration](https://wiki.archlinux.org/title/Font_configuration)
, [Font configuration#Alias](https://wiki.archlinux.org/title/Font_configuration#Alias)
, [Pango.FontDescription](https://docs.gtk.org/Pango/type_func.FontDescription.from_string.html#description)

Programming font:

```
$ sudo pacman -S ttf-jetbrains-mono ttf-nerd-fonts-symbols
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

```
$ sudo pacman -S breeze-icons
```

Change default GTK icon theme:

```
$ ls /usr/share/icons
$ gsettings set org.gnome.desktop.interface icon-theme breeze
```

Ref: [GTK#Basic theme configuration](https://wiki.archlinux.org/title/GTK#Basic_theme_configuration)
, [GTK 3 settings on Wayland](https://github.com/swaywm/sway/wiki/GTK-3-settings-on-Wayland)

Set cursor theme, edit `"~/.config/sway/config"` with:

```
seat seat0 xcursor_theme Adwaita 32
```

Ref: [Sway#Change cursor theme and size](https://wiki.archlinux.org/title/Sway#Change_cursor_theme_and_size)

### Plymouth Theme

Collection: [adi1090x/plymouth-themes](https://github.com/adi1090x/plymouth-themes)

```
$ tar xf spinner_alt.tar.gz
$ sudo cp -r spinner_alt /usr/share/plymouth/themes/
$ sudo plymouth-set-default-theme -l
$ sudo plymouth-set-default-theme -R spinner_alt
```

Ref: [Plymouth#Install new themes](https://wiki.archlinux.org/title/Plymouth#Install_new_themes)

## GPU

AMD. Ref: [AMDGPU#Installation](https://wiki.archlinux.org/title/AMDGPU#Installation)

```
$ sudo pacman -S lib32-mesa vulkan-radeon lib32-vulkan-radeon
```

Intel. Ref: [Intel graphics#Installation](https://wiki.archlinux.org/title/Intel_graphics#Installation)

```
$ sudo pacman -S lib32-mesa vulkan-intel lib32-vulkan-intel
```

## HW Video Acceleration

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

