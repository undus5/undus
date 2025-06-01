+++
title       = "Windows 10/11 Softwares"
#lastmod     = 2025-04-23T14:06:00+08:00
date        = 2025-05-14
showTOC     = true
hidden      = true
weight      = 9100
+++

## Windows ISO

[Windows LTSC Download](https://massgrave.dev/windows_ltsc_links)

[Windows 11 Enterprise LTSC 2024](https://drive.massgrave.dev/zh-cn_windows_11_enterprise_ltsc_2024_x64_dvd_cff9cd2d.iso)
, [Windows 11 IoT Enterprise LTSC 2024](https://drive.massgrave.dev/en-us_windows_11_iot_enterprise_ltsc_2024_x64_dvd_f6b14814.iso)

Windows 11 LTSC to IoT:

```
changepk.exe /ProductKey CGK42-GYN6Y-VD22B-BX98W-J8JXD
```

[Windows 10 Enterprise LTSC 2021](https://drive.massgrave.dev/zh-cn_windows_10_enterprise_ltsc_2021_x64_dvd_033b7312.iso)
, [Windows 10 IoT Enterprise LTSC 2021](https://drive.massgrave.dev/en-us_windows_10_iot_enterprise_ltsc_2021_x64_dvd_257ad90f.iso)

Windows 10 LTSC to IoT:

```
changepk.exe /ProductKey QPM6N-7J2WJ-P88HH-P3YRH-YY74H
```

## BootableUSB

[Rufus](https://rufus.ie/en/)
([Download](https://github.com/pbatard/rufus/releases/download/v4.7/rufus-4.7p.exe))

[Ventoy](https://ventoy.net/en/index.html)
([Download](https://ventoy.net/en/download.html))

## Drivers

[万能驱动 v7.23.1221.1 最终版](https://www.yrxitong.com/h-nd-395.html)
([Download](https://yrxitong6-my.sharepoint.cn/:f:/g/personal/yrxitong_com_yrxitong_com/EpDqzY2EVRBKnD1fI3pOi-4BEBocYXSWEKnpjA5Rm9MeIw))

## Activation

[Microsoft-Activation-Scripts](https://github.com/massgravel/Microsoft-Activation-Scripts)
([Download](https://github.com/massgravel/Microsoft-Activation-Scripts/archive/refs/heads/master.zip))

```
irm https://get.activated.win | iex
```

## Decompressing

[WinRAR](https://dl.lancdn.com/landian/soft/winrar/)
([Download](https://dl.lancdn.com/landian/soft/winrar/v7.01_x64_landian.news.exe), [rarreg.key](https://dl.lancdn.com/landian/soft/winrar/rarreg.key))

[7-Zip](https://www.7-zip.org/)
([Download](https://www.7-zip.org/a/7z2409-x64.exe))

## Office Suite

[Office 2024 Offline Installer](https://gravesoft.dev/office_c2r_links#chinese-simplified-zh-cn)
([Download](https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/zh-cn/Home2024Retail.img))

Office Online Installer:
[Office Deployment Tool](https://officecdn.microsoft.com/pr/wsus/setup.exe)
, [config.office.com](https://config.office.com/deploymentsettings))

```
setup.exe /configure Configuration.xml
```

Ref: [Office C2R Custom Install](https://gravesoft.dev/office_c2r_custom)

[OfficeToolPlus](https://otp.landian.vip/zh-cn/download.html)
([Download](https://otp.landian.vip/redirect/download.php?type=runtime&arch=x64&site=sdumirror)
, [Installation Guide](https://www.coolhub.top/archives/11)
, [Activation Guide](https://www.coolhub.top/archives/14))

## Image Viewer

[Honeyview](https://en.bandisoft.com/honeyview/)
([Download](https://en.bandisoft.com/honeyview/dl.php?web))

## Image Editor

[Paint.NET](https://github.com/paintdotnet/release/releases)

## PDF Viewer

[Sumatra PDF](https://www.sumatrapdfreader.org/free-pdf-reader)
([Download](https://www.sumatrapdfreader.org/download-free-pdf-viewer))

## Video Player

[MPC-HC](https://github.com/clsid2/mpc-hc)
([Download](https://github.com/clsid2/mpc-hc/releases/latest))

## Text Editor

[EmEditor](https://www.emeditor.com/download/)
([Download](https://support.emeditor.com/en/downloads/latest/installer/64))

[VSCodium](https://vscodium.com/)
([Download](https://github.com/VSCodium/vscodium/releases/download/1.100.03093/VSCodiumSetup-x64-1.100.03093.exe))

## Screenshot

[Snipaste](https://www.snipaste.com/)
([Download](https://dl.snipaste.com/win-x64))

## Disk Info

[Crystal Disk](https://crystalmark.info/en/download)
([CrystalMarkRetro](https://crystalmark.info/redirect.php?product=CrystalMarkRetro)
, [CrystalDiskInfo](https://crystalmark.info/redirect.php?product=CrystalDiskInfo)
, [CrystalDiskMark](https://crystalmark.info/redirect.php?product=CrystalDiskMark))

## Web Browser

[Chrome Enterprise]()(https://chromeenterprise.google)
([Download](https://chromeenterprise.google/download/))

[Brave Browser](https://brave.com/)
([Download](https://github.com/brave/brave-browser/releases/latest))

Disable Crypto and AI related components by default:

> Download
> [policy_templates.zip](https://brave-browser-downloads.s3.brave.com/latest/policy_templates.zip)
> , copy files from `admx` into `C:\\Windows\\PolicyDefinitions`
> 
> Press `Win + r`, type and run `gpedit.msc`, will open "Local Group Policy Editor",
> navigate to `Computer Configuration\Administrative Templates\Brave\Brave Software settings`,
> enable whatever options you need.

Visit `brave://policy` from address bar to check the effect.

Ref: [Group Policy](https://support.brave.com/hc/en-us/articles/360039248271-Group-Policy)

## Troubleshooting

解决 Win10 自带输入法不显示选字框:

> 语言设置 \ 中文-选项 \ 微软拼音-选项 \ 勾选"使用以前版本的输入法"

