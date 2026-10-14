_:

{
  hm.modules.common =
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

        if [ ! -d "$BORG_REPO/data" ]; then
          echo "[borg] initializing repository at $BORG_REPO"
          ${pkgs.borgbackup}/bin/borg init --encryption=repokey-blake2
        fi

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

          "${homeDirectory}/projects" \
          "${homeDirectory}/archive" \
          "${homeDirectory}/resources" \
          "${homeDirectory}/areas" \
          "${homeDirectory}/.config/mozilla"

        echo "[borg] pruning old archives"
        ${pkgs.borgbackup}/bin/borg prune \
          --list \
          --show-rc \
          --keep-daily 7 \
          --keep-weekly 4 \
          --keep-monthly 6 \
          --keep-yearly 1

        echo "[borg] compacting repository"
        ${pkgs.borgbackup}/bin/borg compact

        echo "[borg] backup completed successfully"
      '';

      rcloneSyncScript = pkgs.writeShellScript "borg-rclone-sync" ''
        set -euo pipefail

        HOSTNAME="$(hostname)"
        REMOTE_PATH="p052:backups/''${HOSTNAME}"

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

      borgRecover = pkgs.writeShellApplication {
        name = "borg-recover";
        runtimeInputs = [
          pkgs.borgbackup
          pkgs.coreutils
          pkgs.gnugrep
          pkgs.inetutils
          pkgs.rclone
        ];
        text = ''
          set -euo pipefail

          export BORG_REPO="${borgRepo}"
          export BORG_PASSCOMMAND="cat ${borgPassphraseFile}"
          export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

          usage() {
            cat <<'HELP'
          Usage:
            borg-recover                         guided recovery
            borg-recover archives                list available snapshots
            borg-recover files ARCHIVE SEARCH    find paths in a snapshot
            borg-recover restore ARCHIVE PATH [DEST]
                                                restore a path into DEST
            borg-recover fetch [HOSTNAME]        download a repo from Google Drive

          Restore destinations default to a new directory in the current folder.
          HELP
          }

          require_repo() {
            if [[ ! -d "$BORG_REPO/data" ]]; then
              printf 'No local Borg repository at %s. Run: borg-recover fetch [HOSTNAME]\n' "$BORG_REPO" >&2
              exit 1
            fi
            if [[ ! -r "${borgPassphraseFile}" ]]; then
              printf 'Borg passphrase file is missing or unreadable: %s\n' "${borgPassphraseFile}" >&2
              exit 1
            fi
          }

          list_archives() {
            borg list --format '{archive}{NL}'
          }

          fetch_repository() {
            local source_host="''${1:-$(hostname)}"
            if [[ ! "$source_host" =~ ^[A-Za-z0-9._-]+$ ]]; then
              printf 'Invalid hostname: %s\n' "$source_host" >&2
              exit 2
            fi
            if [[ ! -r "${homeDirectory}/.config/rclone/rclone.conf" ]]; then
              printf 'rclone config is missing: %s\n' "${homeDirectory}/.config/rclone/rclone.conf" >&2
              exit 1
            fi
            mkdir -p "$BORG_REPO"
            printf 'Copying p052:backups/%s into %s (existing local files are kept)\n' "$source_host" "$BORG_REPO"
            rclone copy "p052:backups/$source_host" "$BORG_REPO" --verbose
            printf 'Repository download finished. Available snapshots:\n'
            borg list
          }

          search_files() {
            local archive="$1"
            local query="$2"
            borg list --short "::$archive" | grep -F -- "$query" || true
          }

          restore_path() {
            local archive="$1"
            local path="$2"
            local destination="''${3:-$PWD/borg-restore-$(date +%Y%m%d-%H%M%S)}"
            if [[ -z "$path" ]]; then
              printf 'A path inside the archive is required.\n' >&2
              exit 2
            fi
            mkdir -p "$destination"
            printf 'Restoring %s from %s into %s\n' "$path" "$archive" "$destination"
            (cd "$destination" && borg extract --list "::$archive" "$path")
            printf 'Restore finished. Check the files under: %s\n' "$destination"
          }

          if [[ "''${1:-}" == "-h" || "''${1:-}" == "--help" || "''${1:-}" == "help" ]]; then
            usage
            exit 0
          fi

          if [[ ! -r "${borgPassphraseFile}" ]]; then
            printf 'Borg passphrase file is missing or unreadable: %s\n' "${borgPassphraseFile}" >&2
            exit 1
          fi

          case "''${1:-}" in
            -h|--help|help)
              usage
              ;;
            fetch)
              fetch_repository "''${2:-}"
              ;;
            archives)
              require_repo
              list_archives
              ;;
            files)
              if [[ $# -lt 3 ]]; then usage >&2; exit 2; fi
              require_repo
              search_files "$2" "$3"
              ;;
            restore)
              if [[ $# -lt 3 ]]; then usage >&2; exit 2; fi
              require_repo
              restore_path "$2" "$3" "''${4:-}"
              ;;
            "")
              require_repo
              archive_output="$(list_archives)"
              if [[ -z "$archive_output" ]]; then
                printf 'No snapshots found in %s\n' "$BORG_REPO"
                exit 1
              fi
              mapfile -t archives <<< "$archive_output"
              printf 'Available snapshots:\n'
              select archive in "''${archives[@]}"; do
                if [[ -n "''${archive:-}" ]]; then break; fi
                printf 'Choose a snapshot number from the list.\n'
              done
              read -r -p 'Filename or folder name to search for: ' query
              matches="$(search_files "$archive" "$query")"
              if [[ -z "$matches" ]]; then
                printf 'No paths matched %s in %s.\n' "$query" "$archive"
                exit 1
              fi
              printf 'Matching paths (copy the exact path you want):\n%s\n' "$matches"
              read -r -p 'Exact path to restore: ' path
              default_destination="$PWD/borg-restore-$(date +%Y%m%d-%H%M%S)"
              read -r -p "Restore destination [$default_destination]: " destination
              restore_path "$archive" "$path" "''${destination:-$default_destination}"
              ;;
            *)
              usage >&2
              exit 2
              ;;
          esac
        '';
      };

      rcloneMountScript = pkgs.writeShellScript "rclone-mount" ''
        set -euo pipefail

        for remote in p052 p322814; do
          MOUNT="${homeDirectory}/.gdrive/$remote"
          mkdir -p "$MOUNT"
          ${pkgs.rclone}/bin/rclone mount "$remote:" "$MOUNT" \
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
            --allow-non-empty &
        done

        wait
      '';
    in
    {
      home.packages =
        with pkgs;
        [
          rclone
          borgbackup
        ]
        ++ [ borgRecover ];

      systemd.user.services.rclone-mount = {
        Unit = {
          Description = "mount google drive at ~/.gdrive/*";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
          Before = [ "sleep.target" ];
        };

        Service = {
          Type = "simple";
          ExecStart = "${rcloneMountScript}";
          ExecStop = toString (
            pkgs.writeShellScript "rclone-umount" ''
              for remote in p052 p322814; do
                ${pkgs.util-linux}/bin/umount -l "${homeDirectory}/.gdrive/$remote" || true
              done
            ''
          );
          Restart = "on-failure";
          RestartSec = "10s";
        };

        Install = {
          WantedBy = [ "default.target" ];
        };
      };

      systemd.user.services.borg-backup = {
        Unit = {
          Description = "borgbackup";
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
          file = "${homeDirectory}/.nix-config/secrets/google/common/rclone.age";
          path = "${homeDirectory}/.config/rclone/rclone.conf";
          mode = "0600";
        };

        borg = {
          file = "${homeDirectory}/.nix-config/secrets/google/common/borg.age";
          path = "${homeDirectory}/.secrets/borg";
          mode = "0600";
        };
      };
    };
}
