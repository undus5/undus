+++
title       = 'Linux Desktop: Sway, Labwc, GUI Apps'
lastmod     = '2025-12-04'
date        = '2025-11-30'
tags        = []
showSummary = true
showTOC     = true
weight      = 1000
+++

You only need a window manager to do your work.

<!--more-->

## Series Index

1. [Linux Bootstrap Installation](/posts/linux-bootstrap-installation/)
2. [Linux A/B System Updates via BTRFS Snapshot](/posts/linux-ab-system-updates-via-btrfs-snapshot/)
3. [Linux Post Installation: Desktop Preparation](/posts/linux-post-installtion-desktop-preparation/)
4. Linux Desktop: Sway, Labwc, GUI Apps

## Preface

You don't really need a versatile desktop suite, just a window manager can get
your job done, less components, less bugs, more efficient.

If you prefer keyboard navigation, then choose Sway,
if you prefer using mouse to point and click, then choose Labwc.

This guide is based on Arch, but could also work for Debian/Ubuntu and Fedora.

## Sway Labwc

Install [Sway](https://wiki.archlinux.org/title/Sway),
[Labwc](https://wiki.archlinux.org/title/Labwc) and other essential packages:

```
sway swaylock swaybg labwc
xdg-desktop-portal-wlr xdg-desktop-portal-gtk wl-clipboard
wmenu mako wob grim sway-contrib kanshi wev
```

Arch: `xorg-xwayland`\
Debian: `xwayland`\
Fedora: `xorg-x11-server-Xwayland`

[xdg-desktop-portal](https://wiki.archlinux.org/title/XDG_Desktop_Portal):\
xdg-desktop-portal-gtk : necessary component for e.g. file chooser.\
xdg-desktop-portal-wlr : necessary component for e.g. screenshot.\
[wl-clipboard](https://github.com/bugaevc/wl-clipboard) : necessary for ctrl-c ctrl-v function.\
[wmenu](https://codeberg.org/adnano/wmenu) : menu for launching apps and running commands.\
[mako](https://github.com/emersion/mako) : desktop notification.\
[wob](https://github.com/francma/wob) : indicator bar for volume or brightness.\
[grim](https://gitlab.freedesktop.org/emersion/grim) screenshot tool for wayland.\
[sway-contrib](https://github.com/OctopusET/sway-contrib) : grim helper for partial screenshot.\
[kanshi](https://gitlab.freedesktop.org/emersion/kanshi): dynamic output configuration.\
[wev](https://git.sr.ht/~sircmpwn/wev) : detect key name, for configuring keybindings.

I won't discuss their configurations in detail, you can refer to the official documentations.
Here's my configuration for Sway and Labwc:
[waylabrc](https://github.com/undus5/waylabrc).
Instead, I will show you some basic ideas about how I use them.

I use Sway on my physical machines, and Labwc on virtual machines, since
the keybindings would conflict with each other if the VMs also use Sway.

For Sway, since it's keyboard driven and tiling, I bind `Super + 1/2/3/4/5/6/7/8/9/0`,
`Super + q/w/e/r/t/y/u/i/o/p/[/]`, `Super + z/x/c/v/b/n/m` to corresponding
workspaces, and `Super + Shift + ...` to move windows into them. Then I use apps
in maximum mode, one window per workspace for most of time. In this way, I need
to track which workspaces are in use, so I choose built-in swaybar to do this work.

Unfortunately, swaybar is lacking system tray support. But I think it's not a big
problem, you don't really need it, if you want some apps running in the background,
just throw them into a dedicated workspace in the corner and forget, done.

For Labwc, there isn't much to say, all the actions can be invoked from the
right-click context menu. Since it's mouse driven and floating, single workspace
is enough, you just use `Alt + Tab` to switch between windows.

Every time I saw some cosmetic showing offs about tiling window manager from the
internet, I don't feel they are cool or beautiful, I think the real elegant one
is a clean and empty one.

## Terminal

I prefer [foot](https://codeberg.org/dnkl/foot) and
[alacritty](https://alacritty.org/),
both are simple and fast terminal emulators.

## File Manager

Install Nautilus aka [GNOME/Files](https://wiki.archlinux.org/title/GNOME/Files):

Arch, Fedora:

```
nautilus ifuse gvfs gvfs-mtp gvfs-gphoto2 gvfs-afc
```

Debian:

```
nautilus ifuse gvfs gvfs-backends gvfs-fuse
```

[GVFS](https://wiki.archlinux.org/title/File_manager_functionality#Mounting)
is for auto mounting usb drives, mobile devices and trash functionality.

`ifuse gvfs-gphoto2 gvfs-afc` are for
[iOS](https://wiki.archlinux.org/title/IOS) device support. There's a
[glitch](https://sporks.space/2024/09/20/accessing-iphone-photos-and-media-from-nautilus-on-linux/)
after pluging in the iOS device, you can only see the virtual filesystem for iOS
apps, not for photos. To fix this, first open that virtual filesystem for apps,
the URL in the address bar is like `afc://<URL>:3`, change `:3` to `:1` and
press Enter, now you switch to the virtual filesystem for photos.

Set Nautilus as default file manager:

```
xdg-mime default org.gnome.Nautilus.desktop inode/directory
```

When you use "Open With" to open file with some app, it will invoke app's desktop
entry, when the app is a command line app, there's a key-value `Terminal=true`
in its desktop entry file, for example, you want to open a text file with
neovim, Nautilus detected this 'Terminal=true' and would try to run it in the
"default terminal", then how does this default terminal being determined?
I found it from gsettings:

```
(user)$ gsettings get org.gnome.desktop.default-applications.terminal exec
```

It returns `xdg-terminal-exec`, this is the right executable, but this gsettings
key-value is not the one which affect "Open With" behavior.
I've done some experiments, found it seems hard coded, Nautilus always try to
invoke xdg-terminal-exec even when I changing this `exec` value to another executable.
Fortunately, xdg-terminal-exec is maintained as a seperated package,
we could choose not to install it and write our own for simplicity,
just create a script `/usr/local/bin/xdg-terminal-exec` with:

```
#!/bin/bash
foot "${@}"
# alacritty -e "${@}"
```

There's another missing feature when using Nautilus out of GNOME, which is
"open terminal here", and it can be implemented via Nautilus's built-in function
[Custom Scripts](https://wiki.archlinux.org/title/GNOME/Files#Custom_scripts),
but there're some inconvenience in this way, you need to right click on the folder,
select the script from context menu, which means you need to take this action
in the parent folder, which is counter-intuitive for "open terminal here".
Normally we want to do this by right-clicking on the blank inside the target folder,
so "Custom Scripts" is not a good choice here, instead, I recommend using "Open With"
to implement this function, here's how:

Create `/usr/local/bin/open-terminal-here.sh` with:

```
#!/bin/bash
_abspath=$(realpath "${1}")
if [[ -d "${_abspath}" ]]; then
    foot -D "${_abspath}"
    # alacritty --working-directory "${_abspath}"
else
    foot
    # alacritty
fi
```

Create `~/.local/share/applications/open-terminal-here.desktop` with:

```
[Desktop Entry]
Name=Open Terminal Here
Exec=open-terminal-here.sh %F
Icon=foot
Terminal=false
Type=Application
Categories=System;TerminalEmulator;
Keywords=shell;prompt;command;commandline;
MimeType=inode/directory;
```

Apply change:

```
(user)$ update-desktop-database ~/.local/share/applications
```

You may also want to disable "Recent Files":

```
(user)$ rm ~/.local/share/recently-used.xbel
(user)$ ln -s /dev/null ~/.local/share/recently-used.xbel
(user)$ gsettings set org.gnome.desktop.privacy remember-recent-files false
```

## Zip/Unzip

I recommend [PeaZip](https://peazip.github.io/) as GUI archive manager.
There're official packages for Debian and Fedora.

For Arch, install dependency package `qt6pas` first.
Then download peazip tarball and extract to e.g. `/data/apps/peazip`,
use `/data/apps/peazip/res/share/batch/freedesktop_integration/peazip.desktop`
as template to create 2 desktop entries in `~/.local/share/applications/`:

`peazip-extract-newfolder.desktop`:

```
Name=PeaZip Extract Smart
Exec=/data/apps/peazip/peazip -ext2folder %F
Icon=/data/apps/peazip/res/icons/peazip
```

`peazip-add-archive.desktop`:

```
Name=PeaZip Add Archive
Exec=/data/apps/peazip/peazip -add2archive %F
Icon=/data/apps/peazip/res/icons/peazip
MimeType=application/octet-stream;
```

Apply change:

```
(user)$ update-desktop-database ~/.local/share/applications
```

Ref: [Desktop entries](https://wiki.archlinux.org/title/Desktop_entries)

Also recommend installing `7zip` package for zip/unzip in command line.

## Policykit

Tools like [Ventoy](https://www.ventoy.net/) need
[polkit](https://wiki.archlinux.org/title/Polkit)
to evaluate privilege.\

Install packages:

Arch, Fedora: `polkit polkit-gnome`\
Debian: `polkitd policykit-1-gnome`

The executable `/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1` needs
to be added into autostart script for Sway and Labwc.

## Input Method

For input method, I use [Fcitx5](https://fcitx-im.org/wiki/Fcitx_5) and
[RIME](https://rime.im).
Here is my RIME configs for Wubi86 : [rimerc](https://github.com/undus5/rimerc).

Install packages:

Arch, Fedora: `fcitx5 fcitx5-rime fcitx5-gtk fcitx5-qt fcitx5-configtool`\
Debian: `fcitx5 fcitx5-rime fcitx5-frontend-gtk4 fcitx5-frontend-qt6 fcitx5-config-qt`

Add environment variables to `.bashrc`, then relogin user:

```
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
```

The launching command `fcitx5 -d -r` needs
to be added into autostart script for Sway and Labwc.

Ref: [Fcitx5 - ArchWiki](https://wiki.archlinux.org/title/Fcitx5)

## Other Apps

| Category | Arch Packages | Debian | Fedora |
| --- | --- | --- | --- |
| Audio Control | pavucontrol | - | - |
| PDF | zathura zathura-pdf-poppler | - | - |
| Image Viewer | oculante | [oculante](https://github.com/woelper/oculante) | - |
| Video Player | mpv | - | - |
| Ebook Reader | foliate | - | - |
| Audiobook Player | [cozy](https://cozy.sh/) | - | - |
| Text to QR Code | qrencode | - | - |
| QR Code to Text | zbar | zbar-tools | - |
| Web Browser | chromium [brave](https://brave.com/linux/) | - | - |

Brave disable Crypto and AI related components via
[Group Policy](https://support.brave.com/hc/en-us/articles/360039248271-Group-Policy):

Create `/etc/brave/policies/managed/brave-policy.json` :

```
{
  "BraveAIChatEnabled": true,
  "BraveRewardsDisabled": true,
  "BraveWalletDisabled": true,
  "BraveNewsDisabled": true,
  "BraveTalkDisabled": true,
  "BraveVPNDisabled": 1
}
```

Visit `brave://policy` from address bar to check the effect.

For more apps, refer to: [Useful add ons for sway](https://github.com/swaywm/sway/wiki/Useful-add-ons-for-sway).

