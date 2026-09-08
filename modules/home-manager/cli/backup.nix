{
  config,
  pkgs,
  ...
}:

let
  inherit (config.home) homeDirectory;

  borgRepo = "${homeDirectory}/.local/share/borg";
  borgPassphraseFile = "${homeDirectory}/.secrets/borg";

  borgBackupScript = pkgs.writeShellScript "borg-backup" ''
    set -euo pipefail

    export BORG_REPO="${borgRepo}"
    export BORG_PASSCOMMAND="cat ${borgPassphraseFile}"
    export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

    HOSTNAME="$(hostname)"

    # initialize repo if it doesn't exist
    if [ ! -d "$BORG_REPO/data" ]; then
      echo "[borg] initializing repository at $BORG_REPO"
      ${pkgs.borgbackup}/bin/borg init --encryption=repokey-blake2
    fi

    # create archive with timestamp
    ARCHIVE="''${HOSTNAME}-$(date +%Y-%m-%dT%H:%M:%S)"
    echo "[borg] creating archive: $ARCHIVE"

    ${pkgs.borgbackup}/bin/borg create \
      --verbose \
      --filter AME \
      --list \
      --stats \
      --show-rc \
      --compression auto,zstd,6 \
      --exclude-caches \
      --exclude '*.pyc' \
      --exclude '__pycache__' \
      --exclude '.cache' \
      --exclude 'node_modules' \
      --exclude '.direnv' \
      --exclude '.devenv' \
      --exclude '.venv' \
      --exclude 'target' \
      --exclude 'result' \
      --exclude '.git' \
      --exclude '**/mozilla/firefox/*/cache2' \
      --exclude '**/mozilla/firefox/*/startupCache' \
      --exclude '**/mozilla/firefox/*/thumbnails' \
      --exclude '**/mozilla/firefox/*/safebrowsing' \
      --exclude '**/mozilla/firefox/*/storage/temporary' \
      --exclude '**/mozilla/firefox/*/storage/to-be-removed' \
      --exclude '**/mozilla/firefox/*/datareporting' \
      --exclude '**/mozilla/firefox/*/saved-telemetry-pings' \
      --exclude '**/mozilla/firefox/*/crashes' \
      --exclude '**/mozilla/firefox/*/minidumps' \
      --exclude '**/mozilla/firefox/*/gmp-*' \
      --exclude '**/mozilla/firefox/*/sessionstore-logs' \
      --exclude '**/mozilla/firefox/Crash Reports' \
      --exclude '**/mozilla/firefox/Pending Pings' \
      "::$ARCHIVE" \
      "${homeDirectory}/documents" \
      "${homeDirectory}/.config/mozilla"

    # prune old archives (keep 7 daily, 4 weekly, 6 monthly, 1 yearly)
    echo "[borg] pruning old archives"
    ${pkgs.borgbackup}/bin/borg prune \
      --list \
      --show-rc \
      --keep-daily 7 \
      --keep-weekly 4 \
      --keep-monthly 6 \
      --keep-yearly 1

    # compact repository
    echo "[borg] compacting repository"
    ${pkgs.borgbackup}/bin/borg compact

    echo "[borg] backup completed successfully"
  '';

  rcloneSyncScript = pkgs.writeShellScript "borg-rclone-sync" ''
    set -euo pipefail

    HOSTNAME="$(hostname)"
    REMOTE_PATH="p052:backups/''${HOSTNAME}"

    # ensure the borg repo exists before syncing
    if [ ! -d "${borgRepo}/data" ]; then
      echo "[rclone] borg repository not found at ${borgRepo}, skipping sync"
      exit 0
    fi

    echo "[rclone] syncing borg repo to $REMOTE_PATH"

    ${pkgs.rclone}/bin/rclone sync \
      "${borgRepo}" \
      "$REMOTE_PATH" \
      --verbose \
      --transfers 4 \
      --checkers 8 \
      --contimeout 30s \
      --timeout 5m \
      --retries 3 \
      --low-level-retries 10

    echo "[rclone] sync completed successfully"
  '';
in
{
  home.packages = with pkgs; [
    rclone
    borgbackup
  ];
  
  home.activation.createDriveDir = config.lib.dag.entryBefore [ "linkGeneration" ] ''
    mkdir -p "${homeDirectory}/drive"
  '';

  services.syncthing = {
    enable = true;
    guiAddress = "127.0.0.1:8384";
  };

  systemd.user.services.rclone-mount = {
    Unit = {
      Description = "mount google drive at ~/drive";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
      Before = [ "sleep.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount p052 %h/drive \
          --vfs-cache-mode writes \
          --vfs-cache-max-age 24h \
          --vfs-cache-max-size 50G \
          --vfs-read-chunk-size 32M \
          --vfs-read-chunk-size-limit 1G \
          --dir-cache-time 72h \
          --buffer-size 8M \
          --timeout 5m \
          --contimeout 30s \
          --low-level-retries 10 \
          --no-modtime \
          --allow-non-empty
      '';
      ExecStop = "/run/current-system/sw/bin/umount -l %h/drive";
      Restart = "on-failure";
      RestartSec = "10s";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  systemd.user.services.borg-backup = {
    Unit = {
      Description = "borgbackup – create archive for documents, library, projects";
      Wants = [ "network-online.target" ];
      After = [ "network-online.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${borgBackupScript}";
      IOSchedulingClass = "idle";
      CPUSchedulingPolicy = "idle";
      Nice = 19;
    };
  };

  systemd.user.timers.borg-backup = {
    Unit = {
      Description = "schedule borgbackup daily";
    };

    Timer = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "30min";
    };

    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  systemd.user.services.borg-rclone-sync = {
    Unit = {
      Description = "sync borg repository to google drive (p052:backups/HOSTNAME)";
      Wants = [ "network-online.target" ];
      After = [
        "network-online.target"
        "borg-backup.service"
      ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${rcloneSyncScript}";
      IOSchedulingClass = "idle";
      CPUSchedulingPolicy = "idle";
      Nice = 19;
    };
  };

  systemd.user.timers.borg-rclone-sync = {
    Unit = {
      Description = "schedule borg rclone sync after backup";
    };

    Timer = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "45min";
      OnUnitActiveSec = "1h";
    };

    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  age.secrets = {
    rclone = {
      file = "${homeDirectory}/.nix-config/secrets/rclone.age";
      path = "${homeDirectory}/.config/rclone/rclone.conf";
      mode = "0600";
    };

    borg = {
      file = "${homeDirectory}/.nix-config/secrets/borg.age";
      path = "${homeDirectory}/.secrets/borg";
      mode = "0600";
    };
  };
}
