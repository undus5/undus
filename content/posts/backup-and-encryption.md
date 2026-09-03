+++
title       = "Backup and Encryption"
lastmod     = 2024-11-24T17:11:00+08:00
date        = 2023-04-14
showTOC     = true
weight      = 1000
showSummary = false
#hidden      = true
+++

Data is priceless, pay more attention.

<!--more-->

## Backup & Syncing

To make backup and syncing easier, keep data under a dedicated directory, using
subfolders to sort, then syncing to other storage devices or computers
periodically.

To sync data to other storage devices, use
[FreeFileSync](https://freefilesync.org/download.php) (Linux/Win/Mac) or
[rsync(1)](https://man.archlinux.org/man/rsync.1) command (Linux/Mac) or
just copying and pasting.

```
rsync -aP --del source_dir/ target_dir
```

Options:\
`-a`  recurse into directories, keep symlinks, preserve permission,
modification time, etc.\
`-P`  show progress during transfer.\
`--del`  &nbsp; remove files which are no longer exist in the sourse directory.

If `target_dir` doesn't exists, it will be created automatically.

There's difference about `source_dir` between "with trailing slash" and
"without trailing slash". Without trailing slash, the result will be a subfolder
like `target_dir/source_dir`.

To syncing data to other computers, use [Syncthing](https://syncthing.net/).

## Password Manager

Use a password manager to manage web accounts,
generate different random long passwords for each.
If you use same password for all accounts, one account leaks, all other accounts
would be at risks.

[KeePass](https://keepass.info/) is an open source offline password manager,
it's encrypted `kdbx` file becomes a sort of standard,
there are several third-party apps offer cross-platform support and useful
features which better than the official one.

[KeePassXC](https://keepassxc.org/download/) (Linux/Win/Mac)
, [KeePassDX](https://www.keepassdx.com/) (Android)
, [KeePassium](https://keepassium.com/) (iOS)

Backup the `.kdbx` file with caution.

## SIM Lock

SIM card has a built-in lock, if enabled, you need to unlock it with passcode
when powering on the device or inserting to a running one,
no longer need to worry that your number be exploited when losing your phone.

To enable simlock, you need to set a 4-8 digits PIN code for unlocking. The SIM
card would be disabled if you type wrong PIN code for 3 times. Before enabling
simlock, you must get PUK code first, it can be used to reset SIM card's status,
in case of forgetting the PIN code. You can find PUK code from the larger piece
of the card which wrapping the SIM card or asking from the mobile service
provider if the larger piece is losing, then save it to the password manager.

## Disk Encryption

Ref: [Disk Encryption - Wikipedia](https://en.wikipedia.org/wiki/Disk_encryption)

Encrypting disk and system can prevent data from being extracted when computer
is lost or sent to be maintained, it needs to be unlocked with password or
keyfile or even physical hardware key to read and write data.

Different operating systems provide different tools to accomplish this task,
for Linux, it's [LUKS - Wikipedia](https://en.wikipedia.org/wiki/Linux_Unified_Key_Setup),
for Windows, it's [BitLocker - Wikipedia](https://en.wikipedia.org/wiki/BitLocker).

It sounds a bit intimidating, but is worth taking time to learn and set up.
