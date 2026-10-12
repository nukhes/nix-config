# Backup and Recovery

## What is backed up

The `borg-backup` user timer runs once a day. Each run creates a compressed,
encrypted Borg snapshot containing these paths from your home directory:

- `projects`
- `archive`
- `resources`
- `areas`
- `.config/mozilla`

Build output and caches are excluded, including `.git`, `node_modules`, virtual
environments, `result`, common Firefox caches, and crash reports. Anything
outside the listed paths is not included. In particular, this is not a full
system backup.

Borg keeps 7 daily, 4 weekly, 6 monthly, and 1 yearly snapshot. The repository
is stored locally at `~/.local/share/borg`.

## Google Drive copy

The `borg-rclone-sync` user timer copies the local repository to
`p052:backups/<hostname>`. The `rclone sync` operation mirrors the local Borg
repository; it is not an independent snapshot history. Pruning locally and
syncing can also remove old repository data from the remote copy. Keep this in
mind if the local disk is damaged before the latest sync completes.

## Before you need recovery

Recovery requires both:

- The Borg passphrase, provided by `~/.secrets/borg`.
- The rclone configuration and Google Drive credentials, provided by
  `~/.config/rclone/rclone.conf`, when fetching from Drive.

These files are managed as age secrets in this configuration. Keep access to
the age identity needed to decrypt them (on NixOS this is commonly the SSH host
key under `/etc/ssh/`). The Borg repository contains its encryption key, but it
cannot be opened without the passphrase. Losing both the secrets and the
identity that decrypts them can make the backup unrecoverable.

## Guided restore

Run `borg-recover` with no arguments. It lists snapshots, asks for a filename or
folder to search for, displays matching paths, then asks which exact path to
restore and where to put it. The default destination is a new `borg-restore-*`
folder in the current directory. Restoring there avoids overwriting the
original files. Borg keeps the archived path structure beneath that folder, so
for example a path listed as `home/user/projects/notes.txt` will be restored
under `DEST/home/user/projects/notes.txt`.

Use an empty folder or a destination with enough free space. Inspect the
recovered files before moving them back to their original locations.

## Command reference

```sh
# List snapshots in the local repository
borg-recover archives

# Search paths in one snapshot; use the exact snapshot name from `archives`
borg-recover files 'HOSTNAME-YYYY-MM-DDTHH:MM:SS' 'notes.txt'

# Restore one exact path into a chosen directory
borg-recover restore 'HOSTNAME-YYYY-MM-DDTHH:MM:SS' \
  'home/user/projects/notes.txt' "$HOME/recovered-files"

# Fetch a repository copy from Drive, for this computer or another host
borg-recover fetch
borg-recover fetch x200
```

`fetch` copies from `p052:backups/<hostname>` into the local repository and
does not delete existing local files. After it finishes, use `archives` or the
guided restore. The chosen host must have a corresponding folder in Drive, and
the local Borg passphrase must be valid for that repository.

## Recovery on a replacement system

1. Install this configuration and activate the common Home Manager module so
   `borg-recover`, Borg, and rclone are available.
2. Restore/decrypt the `rclone` and `borg` age secrets. Confirm the resulting
   files are `~/.config/rclone/rclone.conf` and `~/.secrets/borg`.
3. Run `borg-recover fetch <old-hostname>` to download that host's repository.
4. Run `borg-recover` and restore files into a separate directory.

If the machine is still working but a local file is missing, skip the fetch:
the daily local snapshots are already available through `borg-recover`.

## Check the scheduled jobs

```sh
systemctl --user list-timers 'borg-*'
systemctl --user status borg-backup.service borg-rclone-sync.service
```

To run a backup or sync immediately:

```sh
systemctl --user start borg-backup.service
systemctl --user start borg-rclone-sync.service
```

Check service logs with `journalctl --user -u borg-backup.service` or
`journalctl --user -u borg-rclone-sync.service`.
