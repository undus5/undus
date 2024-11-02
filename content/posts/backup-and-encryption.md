+++
title       = "Backup and Encryption"
lastmod     = 2024-02-20T19:30:00+08:00
date        = 2023-04-14
showSummary = true
showTOC     = true
weight      = 1000
+++

Data is priceless, pay more attention.

<!--more-->

## Backup

The simplest way is the best way. My data is gathered and maintained under a dedicated directory,
so I just syncing it manually to backup.

There are two methods to accomplish this task, a GUI one and a CLI one,
both can compare and mirror the changed files.

The GUI method is [FreeFileSync](https://freefilesync.org/download.php) (Linux / Windows / macOS).

The CLI method is `rsync` command (Linux / macOS):
```
rsync -va -P --del source_dir/ target_dir
```
Options description:
-  `-v` &nbsp; increase verbosity.
-  `-a` &nbsp; recurse into directories, keep symlinks, preserve permission, modification time, etc.
-  `-P`  show progress during transfer.
-  `--del`  &nbsp; remove files which are no longer exist in the sourse directory.

If "target_dir" doesn't exists, it will be created automatically.

There's difference about "source_dir" between "with trailing slash" and "without trailing slash".
Without trailing slash, the result will be a subfolder like "target_dir/source_dir".

## Password Manager

Everyone should use a password manager to manage their web accounts,
generate and set different random long passwords for each.
If you use same password for all accounts, one account leaks, all accounts would be leaked.

[KeePass](https://keepass.info/) is an opensource and offline password manager,
it's encrypted `kdbx` file becomes a sort of standard,
there are several third-party apps offer cross-platform support and useful features
which better than the official one.

[KeePassXC](https://keepassxc.org/download/) (Linux / Windows / macOS)
, [KeePassDX](https://www.keepassdx.com/) (Android)
, Strongbox (iOS)

Backup the `.kdbx` file with caution.

## SIM Lock

SIM card has a built-in lock, if enabled, you need to unlock it with passcode
when powering on the phone or inserting to another phone,
no longer need to worry that your number be exploited when losing the phone.

To enable simlock, you need to set a 4-8 digits PIN code for unlocking. The SIM card would be disabled
if you type wrong PIN code for 3 times. Before enabling simlock, you must get PUK code first,
it can be used to reset SIM card's status.
You can find PUK code from the larger piece of the card which wrapping the SIM card
or asking from the mobile service provider if the larger piece is losing,
then save it to the password manager.

## Full Disk Encryption

Encrypting disk and system can prevent data from being extracted when computer is lost
or under maintenance, it needs to be unlocked with password to read and write.

Different operating systems provide different technologies to accomplish this task,
for Linux, it's LUKS (Linux Unified Key Setup), for Windows, it's BitLocker.

It sounds a bit intimidating, but it's worth learning and adopting.

