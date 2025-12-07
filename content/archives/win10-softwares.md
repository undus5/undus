+++
title       = "Windows 10/11 Softwares"
lastmod     = 2025-08-31
date        = 2025-05-14
showTOC     = true
hidden      = true
weight      = 9100
+++

| Category | Software Download |
| --- | --- |
| Windows ISO | [Windows LTSC Download](https://massgrave.dev/windows_ltsc_links) |
| Windows 11 LTSC to IoT | \`changepk.exe /ProductKey CGK42-GYN6Y-VD22B-BX98W-J8JXD\` |
| Windows 10 LTSC to IoT | \`changepk.exe /ProductKey QPM6N-7J2WJ-P88HH-P3YRH-YY74H\` |
| Bootable USB | [Rufus](https://rufus.ie/en/) , [Ventoy](https://ventoy.net/en/index.html) |
| Drivers | [万能驱动 v7.23.1221.1 最终版](https://www.yrxitong.com/h-nd-395.html) ([One Drive](https://yrxitong6-my.sharepoint.cn/:f:/g/personal/yrxitong_com_yrxitong_com/EpDqzY2EVRBKnD1fI3pOi-4BEBocYXSWEKnpjA5Rm9MeIw)) |
| Activation | [Microsoft-Activation-Scripts](https://github.com/massgravel/Microsoft-Activation-Scripts) (\`irm https://get.activated.win \| iex\`) |
| Zip/Unzip | [WinRAR](https://dl.lancdn.com/landian/soft/winrar/) , [NanaZip](https://github.com/M2Team/NanaZip) , [7-Zip](https://www.7-zip.org/) |
| Office Suite | [Office 2024 Offline Installer](https://gravesoft.dev/office_c2r_links) |
| Office Suite | [Office Deployment Tool (Online)](https://officecdn.microsoft.com/pr/wsus/setup.exe) , [config.office.com](https://config.office.com/deploymentsettings) |
| Office Suite | [Office C2R Custom Install](https://gravesoft.dev/office_c2r_custom) : \`setup.exe /configure Configuration.xml\` |
| OfficeToolPlus | [OfficeToolPlus](https://otp.landian.vip/zh-cn/download.html) , [Installation Guide](https://www.coolhub.top/archives/11) , [Activation Guide](https://www.coolhub.top/archives/14)) |
| Image Viewer | [Honeyview](https://en.bandisoft.com/honeyview/) |
| Image Editor | [Paint.NET](https://github.com/paintdotnet/release/releases) |
| PDF Viewer | [Sumatra PDF](https://www.sumatrapdfreader.org/free-pdf-reader) |
| Video Player | [MPC-HC](https://github.com/clsid2/mpc-hc) |
| Notepad Alternativj | [EmEditor](https://www.emeditor.com/download/) |
| Screenshot | [Snipaste](https://www.snipaste.com/) |
| Disk Info | [Crystal Disk](https://crystalmark.info/en/download) |
| Web Browser | [Brave Browser](https://brave.com/) , [Chrome Enterprise](https://chromeenterprise.google) |

Brave Browser disable Crypto and AI related components via
[Group Policy](https://support.brave.com/hc/en-us/articles/360039248271-Group-Policy):

1. Download
[policy_templates.zip](https://brave-browser-downloads.s3.brave.com/latest/policy_templates.zip)
, copy files from `admx` into `C:\\Windows\\PolicyDefinitions`

2. Press `Win + r`, type and run `gpedit.msc`, will open "Local Group Policy Editor",
navigate to `Computer Configuration\Administrative Templates\Brave\Brave Software settings`,
enable whatever options you need.

3. Visit `brave://policy` from address bar to check the effect.



修复 Win10 自带输入法不显示选字框:

> 语言设置 \ 中文-选项 \ 微软拼音-选项 \ 勾选"使用以前版本的输入法"

修复美版系统中文乱码:

Windows 11:

> Settings -> Time & language -> Language & region -> Administrative language settings\
-> Change system locale (Language for non-Unicode programs)\
-> Current system locale: Chinese (Simplified, Mainland China)\
-> Uncheck Beta: Use Unicode UTF-8

Windows 10:

> Settings -> Time & language -> Language -> Administrative language settings\
-> Change system locale (Language for non-Unicode programs)\
-> Current system locale: Chinese (Simplified, Mainland China)\
-> Uncheck Beta: Use Unicode UTF-8

欢迎界面中文显示: Region -> Administrative -> Copy settings -> 打勾底部两选项

LTSC disable auto updates:

> `Win + r` -> `gpedit.msc`\
-> `Computer Configuration\Administrative Templates\Windows Components\Windows Update`\
-> disable `"Configure Automatic Updates"`\
-> enable `Remove access to use all Windows update features`

