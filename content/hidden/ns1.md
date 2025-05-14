+++
title       = "Switch V1"
showSummary = true
weight      = 5000
date        = 2023-07-22
lastmod     = 2024-10-01T12:16:00+08:00
+++

Shh~ Do it quietly.

<!--more-->

## Wiki

[SwitchPirates Wiki](https://www.reddit.com/r/SwitchPirates/wiki/index/)
, [Switch Hacking is Easy](https://rentry.co/SwitchHackingIsEasy)

## Firmware

[Darthsternie's Firmware](https://darthsternie.net/switch-firmwares/)
, [NX_Firmware](https://github.com/THZoria/NX_Firmware)\
Upgrade with daybreak (bundled with atmosphere)

## Atmosphere

[Atmoshpere](https://github.com/Atmosphere-NX/Atmosphere/releases/latest)
, [Sigpatches](https://gbatemp.net/threads/sigpatches-for-atmosphere-hekate-fss0-fusee-package3.571543/)

## RCM

Just use a paperclip as jig to make short circuit (pin 1 and pin 10).

Power off your console and place the jig inside of the right railing.

Hold the (VOL +) button and press the power button.
Your Switch display will be black, do not panic, this is normal and
means that you're booted into RCM.

## Injectors

[WebRCM](https://github.com/webrcm/webrcm.github.io) (Web Browser)
, [Rekado](https://github.com/MenosGrante/Rekado/releases/latest) (Android)
, [TegraRcmGUI](https://github.com/eliboa/TegraRcmGUI/releases/latest) (Windows)

## Payloads

[Hekate](https://github.com/CTCaer/hekate/releases/latest/) Custom Bootloader

[TegraExplorer](https://github.com/suchmememanyskill/TegraExplorer/releases/latest/)
&nbsp;
Export Firmware

## APPs

[DBI](https://github.com/rashevskyv/dbi/releases/latest)
&nbsp;
Game Installer

[JKSV](https://github.com/J-D-K/JKSV/releases/latest)
&nbsp;
Game Save Data Manager

[NXMP](https://github.com/proconsule/nxmp/releases/latest)
&nbsp;
Video Player

## Necessary Files

`/bootloader/hekate_ipl.ini`:

```
[config]
autoboot=0
autoboot_list=0
bootwait=3
backlight=100
autohosoff=0
autonogc=1
updater2p=0
bootprotect=0

[Atmosphere CFW]
fss0=atmosphere/package3
emummcforce=1
kip1patch=nosigchk
icon=bootloader/res/icon_payload.bmp

[Stock SysNAND]
fss0=atmosphere/package3
stock=1
emummc_force_disable=1
icon=bootloader/res/icon_switch.bmp
```

`/exosphere.ini`:

```
[exosphere]
debugmode=1
debugmode_user=0
disable_user_exception_handlers=0
enable_user_pmu_access=0
blank_prodinfo_sysmmc=0
blank_prodinfo_emummc=1
allow_writing_to_cal_sysmmc=0
log_port=0
log_baud_rate=115200
log_inverted=0
```

`/atmosphere/hosts/default.txt`:

```
# Block Nintendo Servers
127.0.0.1 *nintendo.*
127.0.0.1 *nintendo-europe.com
127.0.0.1 *nintendoswitch.*
95.216.149.205 *conntest.nintendowifi.net
95.216.149.205 *ctest.cdn.nintendo.net
```

