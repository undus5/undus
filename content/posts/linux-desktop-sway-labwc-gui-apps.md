+++
title       = 'Linux Desktop: Sway, Labwc, GUI Apps'
lastmod     = '2026-03-14'
date        = '2025-11-30'
tags        = ['linux']
showSummary = true
showTOC     = true
weight      = 1000
+++

You only need a window manager to do your work.

<!--more-->

## Series Index

1. [Linux Bootstrap Installation](/posts/linux-bootstrap-installation/)
2. [Linux A/B System Updates via BTRFS Snapshot](/posts/linux-ab-system-updates-via-btrfs-snapshot/)
3. [Linux Post Installation](/posts/linux-post-installtion/)
4. Linux Desktop: Sway, Labwc, GUI Apps
5. [Linux Live ISO Packaging](/posts/linux-live-iso-packaging/)

## Preface

You don't really need a versatile desktop suite, just a window manager can get
your job done, less components, less bugs, more efficient.

If you prefer keyboard navigation, then use Sway,
if you prefer using mouse to point and click, then then Labwc.

This guide is distro independent, tested on Arch and Fedora.

## Regular User

Install [xdg-user-dirs](https://wiki.archlinux.org/title/XDG_user_directories)
package, it's for managing well known user directories
e.g. Desktop, Documents, Downloads etc.

Create regular user:

```
(root)# useradd -G wheel user1
(root)# passwd user1
```

`wheel` is the superuser group for sudo in Arch and Fedora, for Debian,
it's named `sudo`.

## GUI Fonts

Install Noto fonts related packages:

Arch: `fontconfig noto-fonts noto-fonts-cjk noto-fonts-emoji`

Fedora: `fontconfig default-fonts`

The default lookup order for CJK fonts would pick wrong characters in some cases,
such as for chinese words "关于" and "复制", you will notice the mismatch if
there were wrong charaters.
To fix this, adjust fallback font order by creating `/etc/fonts/local.conf` with:

```
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
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
</fontconfig>
```

Later you could add custom fonts under user home directory
`~/.local/share/fonts/`, then create `~/.config/fontconfig/fonts.conf`
with same format to override default fonts. Use
[fc-cache(1)](https://man.archlinux.org/man/fc-cache.1) `fc-cache -f -v` to
rebuild font cache, use [fc-list(1)](https://man.archlinux.org/man/fc-list.1)
`fc-list : family` to check whether custom font families are applied correctly.

[Jetbrains Mono](https://www.jetbrains.com/lp/mono/) is prefered as the default
monospace font, it's good for programming and terminal display.

Ref: [Font configuration#Fontconfig configuration](https://wiki.archlinux.org/title/Font_configuration#Fontconfig_configuration)
, [Font configuration#Alias](https://wiki.archlinux.org/title/Font_configuration#Alias)

## KMSCON

[KMSCON](https://github.com/kmscon/kmscon) is a modern TTY alternative
which support CJK fonts, xkb configs, mouse, GPU rendering, etc.

Arch: `seatd kmscon`\
Fedora: `seatd kmscon kmscon-freetype`

`seatd` is required for running GUI application after KMSCON, or you will
encounter error "libseat no backend was able to open a seat".

Enable seatd:

```
(root)# usermod -aG seat user1
(root)# systemctl enable seatd
(root)# systemctl start seatd
```

Create config file `/etc/kmscon/kmscon.conf`:

```
font-size=16
xkb-layouts=us
xkb-options=ctrl:nocaps
```

Disable built-in getty and enable kmsconvt:

```
(root)# systemctl disable getty@.service
(root)# systemctl enable kmsconvt@.service
```

Login sessions launched by KMSCON are treated as remote sessions, which means
`poweroff` and `reboot` commands for regular user need authentication for
administritve user, to solve this problem, add polkit rules to bypass this
authentication, `/etc/polkit-1/rules.d/20-remote-shutdown.rules`:

```
polkit.addRule(function(action, subject) {
   if ((action.id == "org.freedesktop.login1.power-off" ||
        action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
        action.id == "org.freedesktop.login1.reboot" ||
        action.id == "org.freedesktop.login1.reboot-multiple-sessions") &&
       subject.isInGroup("wheel")) {
      return polkit.Result.YES;
   }
});
```

Ref: [Polkit#Configuration](https://wiki.archlinux.org/title/Polkit#Configuration)

To start a GUI application, a wrapper command is required since KMSCON is
already using the GPU:

```
(user)$ kmscon-launch-gui sway
```

Ref: [KMSCON - ArchWiki](https://wiki.archlinux.org/title/KMSCON)

## Sway Labwc

Install [Sway](https://wiki.archlinux.org/title/Sway),
[Labwc](https://wiki.archlinux.org/title/Labwc) and other essential packages:

```
sway swaylock swaybg labwc wl-clipboard wmenu fuzzel mako wob kanshi grim wev
xdg-desktop-portal-gtk
```

[xdg-desktop-portal](https://wiki.archlinux.org/title/XDG_Desktop_Portal):\
xdg-desktop-portal-gtk : necessary component for e.g. file chooser.\
[wl-clipboard](https://github.com/bugaevc/wl-clipboard) : necessary for ctrl-c ctrl-v function.\
[wmenu](https://codeberg.org/adnano/wmenu) : menu for launching apps and running commands.\
[fuzzel](https://codeberg.org/dnkl/fuzzel) : app launcher (desktop entry)\
[mako](https://github.com/emersion/mako) : desktop notification.\
[wob](https://github.com/francma/wob) : indicator bar for volume or brightness.\
[kanshi](https://gitlab.freedesktop.org/emersion/kanshi): dynamic output configuration.\
[grim](https://gitlab.freedesktop.org/emersion/grim) screenshot tool for wayland.\
[wev](https://git.sr.ht/~sircmpwn/wev) : detect key name, for configuring keybindings.\
[sway-contrib](https://github.com/OctopusET/sway-contrib) : grim helper for partial screenshot.

We won't discuss their configurations in detail, you can refer to the official documentations.
Instead, I will show you some basic ideas about how I use them.

For Sway, since it is keyboard driven and tiling, I bind `Super + 1/2/3/4/5/6/7/8/9/0`,
`Super + q/w/e/r/t/y/u/i/o/p`, `Super + z/x/c/v/b/n/m` to corresponding
workspaces, and `Super + Shift + ...` to move windows into them. Then I use apps
in maximum mode, one window per workspace for most of time. In this way, I need
to track which workspaces are in use, so I choose built-in swaybar to do this work.

Unfortunately, swaybar is lacking system tray support. But I think it's not a big
problem, you don't really need it, if you want some apps running in the background,
just throw them into a dedicated workspace in the corner. Some apps may keep
running in the background when you click the cross button, such as Steam, make
sure exit from the main menu; some apps may offer options to disable background
running, such as Telegram.

For Labwc, there isn't much to say, all the actions can be invoked from the
right-click context menu. Since it's mouse driven and floating, single workspace
is enough, you just use `Alt + Tab` to switch between windows.

That's all. Just keep it simple and clean.

## Terminal

I prefer [foot](https://codeberg.org/dnkl/foot) and
[alacritty](https://alacritty.org/),
both are simple and fast terminal emulators.

## GTK Theme

```
(user)$ gsettings set org.gnome.desktop.interface color-scheme prefer-dark
(user)$ gsettings set org.gnome.desktop.interface color-scheme default
```

Ref: [GTK#Basic theme configuration](https://wiki.archlinux.org/title/GTK#Basic_theme_configuration)
, [GTK 3 settings on Wayland](https://github.com/swaywm/sway/wiki/GTK-3-settings-on-Wayland)

## Qt Theme

IMHO, if you're not intended to use KDE desktop environment, then avoid choosing
KDE replated components, since they are tightly coupled with the KDE framework,
lots of dependencies would be installed.

The original [trialuser02/qt6ct](https://github.com/trialuser02/qt6ct)
is archived, although there is a successor
[trialuser/qt6ct](https://www.opencode.net/trialuser/qt6ct), I decided not
dealing with KDE apps anymore. For other independent Qt apps, they usually
work well by default, no need tools like qt5ct/qt6ct get involved.

## Icon Theme

Install the fallback
[icon theme](https://wiki.archlinux.org/title/Icons) `hicolor-icon-theme` first.

Custom icons can be put under `~/.local/share/icons/` or `~/.icons`,
for example, create `~/.local/share/icons/hicolor/`, put
your icons into corresponding size directories such as `.../hicolor/128x128/apps/`.

Ref: [Icon Theme Specification](https://specifications.freedesktop.org/icon-theme/latest/#directory_layout).

Set GTK app icon theme:

```
(user)$ ls /usr/share/icons
(user)$ gsettings set org.gnome.desktop.interface icon-theme Adwaita
```

[papirus-icon-theme](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme)
is a good third-party icon theme.

## Mouse Cursor Theme

The location for mouse cursor themes is same as icons themes, see above section.

Set cursor theme and size for sway in `~/.config/sway/config`:

```
# seat <name> xcursor_theme <theme> [<size>]
seat seat0 xcursor_theme default 24
seat seat0 xcursor_theme breeze_cursors 32
```

Ref: [sway-input(5)](https://man.archlinux.org/man/sway-input.5.en)

Set cursor theme and size for labwc in `~/.config/labwc/environment`:

```
XCURSOR_THEME=breeze_cursors
XCURSOR_SIZE=32
```

Ref: [labwc-config(5)](https://labwc.github.io/labwc-config.5.html)

## File Manager

Nautilus aka [GNOME/Files](https://wiki.archlinux.org/title/GNOME/Files) is a
good one.

Packages for Arch and Fedora: `nautilus ifuse gvfs gvfs-mtp gvfs-gphoto2 gvfs-afc`

[GVFS](https://wiki.archlinux.org/title/File_manager_functionality#Mounting)
is for auto mounting usb drives, mobile devices and trash functionality.

`ifuse gvfs-gphoto2 gvfs-afc` are for
[iOS](https://wiki.archlinux.org/title/IOS) device support. There's a
[glitch](https://sporks.space/2024/09/20/accessing-iphone-photos-and-media-from-nautilus-on-linux/)
after pluging in the iOS device, you can only see the virtual filesystem for iOS
apps, not for photos. To fix this, first open that virtual filesystem for apps,
the URL in the address bar is like `afc://<URL>:3`, change `:3` to `:1` and
press Enter, now you switch to the virtual filesystem for photos.

Set nautilus as default file manager:

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
abspath=$(realpath "${1}")
if [[ -d "${abspath}" ]]; then
    foot -D "${abspath}"
    # alacritty --working-directory "${abspath}"
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
(user)$ gsettings set org.gnome.desktop.privacy remember-recent-files false
```

## Zip/Unzip

I recommend [PeaZip](https://peazip.github.io/) as GUI archive manager.

Install dependency package `qt6pas` first.
Then download peazip tarball and extract to, say `~/apps/peazip`,
then use `~/apps/peazip/res/share/batch/freedesktop_integration/peazip.desktop`
as template to create desktop entries under `~/.local/share/applications/`:

`peazip-extract-newfolder.desktop`:

```
Name=PeaZip Extract Smart
Exec=bash -c '~/apps/peazip/peazip -ext2folder "$@"' peazip %F
Icon=peazip_extract
```

`peazip-add-archive.desktop`:

```
Name=PeaZip Add Archive
Exec=bash -c '~/apps/peazip/peazip -add2archive "$@"' peazip %F
Icon=peazip_add
MimeType=application/octet-stream;
```

`Exec=` needs absolute path if provided, but here we did a little trick to avoid
hardcoding user home directory, by using
[bash(1)](https://man.archlinux.org/man/bash.1) to expand `~`.

There're more desktop entry examples under
`peazip/res/share/batch/freedesktop_integration/additional-desktop-files`.

Apply change:

```
(user)$ update-desktop-database ~/.local/share/applications
```

Ref: [Desktop entries](https://wiki.archlinux.org/title/Desktop_entries)
, [Registered Categories](https://specifications.freedesktop.org/menu/latest/category-registry.html#main-category-registry)

Also recommend installing `7zip` package for zip/unzip in command line.

## Policykit

Tools like [Ventoy](https://www.ventoy.net/) need
[polkit](https://wiki.archlinux.org/title/Polkit)
to evaluate privilege.

Packages for Arch and Fedora: `polkit mate-polkit`

The executable needs to be added into autostart script for Sway and Labwc.

Excutable for Arch: `/usr/lib/mate-polkit/polkit-mate-authentication-agent-1`\
Excutable for Fedora: `/usr/libexec/polkit-mate-authentication-agent-1`

## Input Method

For input method, I use [Fcitx5](https://fcitx-im.org/wiki/Fcitx_5) and
[RIME](https://rime.im).
Here is my RIME configs for Wubi86:
[rime-wubi86s](https://github.com/undus5/rime-wubi86s).

Packages for Arch and Fedora:
`fcitx5 fcitx5-gtk fcitx5-qt fcitx5-configtool fcitx5-rime`

Add environment variables to `.bashrc`, then relogin user:

```
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
```

The launching command `fcitx5 -d -r` needs
to be added into autostart script for Sway and Labwc.

Ref: [Fcitx5 - ArchWiki](https://wiki.archlinux.org/title/Fcitx5)

## Other Apps

| Category | Arch | Fedora |
| --- | --- | --- |
| Audio Control | pavucontrol | - |
| PDF | zathura zathura-pdf-poppler | - |
| Image Viewer | swayimg | - |
| Image Editor | [photoflare](https://github.com/PhotoFlare/photoflare) | - |
| Video Player | mpv | - |
| Ebook Reader | [KOReader](https://koreader.rocks/) | - |
| Audiobook Player | - | - |
| Web Browser | [brave-origin](https://versions.brave.com/), [helium](https://github.com/imputnet/helium-linux/releases/latest), [ungoogled-chromium](https://github.com/ungoogled-software/ungoogled-chromium), [waterfox](https://www.waterfox.com/download/) | - |
| Text to QR Code | qrencode | - |
| QR Code to Text | zbar | zbar-tools |

Set default browser:

```
(user)$ xdg-settings set default-web-browser brave-origin.desktop
```

Ungoogled Chromium initialization:

Go to chrome://flags, search for `#extension-mime-request-handling` flag
and set it to `Always prompt for install`, then download and install extension
[chromium-web-store](https://github.com/NeverDecaf/chromium-web-store),
without changing the flag ahead, you will encounter error
"Package is invalid: CRX_REQUIRED_PROOF_MISSING". Pin the extension badge in
toolbar and clicking it to update extensions.

Another useful flag is `#disable-top-sites`, which can disable recently viewed
sites for the new tab page.

## More Apps

For more apps, refer to: [Useful add ons for sway](https://github.com/swaywm/sway/wiki/Useful-add-ons-for-sway).
