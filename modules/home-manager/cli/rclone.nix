{
  config,
  pkgs,
  ...
}:

let
  inherit (config.home) homeDirectory;
in
{
  home.packages = with pkgs; [ rclone restic ];

  xdg.configFile."restic/excludes.txt".text = ''
    /.cache
    /.ollama
    /.local/share/Trash
    /.thumbnails
    /.var
    /.npm
    /.var/app/**/.cache
    /.config/**/Cache
    /.config/**/cache
    /.config/**/GPUCache
    /.config/**/Code Cache
    /.config/**/Crash Reports
    /.config/**/Crashpad
    /.config/**/Session Storage
    /.config/**/Service Worker/CacheStorage
    /.mozilla/firefox/**/cache2
    /.mozilla/firefox/**/startupCache
  '';

  systemd.user.services.restic-backup = {
    Unit = {
      Description = "Restic backup to Google Drive via Rclone";
      After = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      Environment = [
        "RESTIC_REPOSITORY=rclone:p052:backup/hackbook/restic"
        "RESTIC_PASSWORD_FILE=${homeDirectory}/.secrets/restic"
        "GOMAXPROCS=1"
      ];
      
      ExecStart = "${pkgs.writeShellScript "restic-backup-run" ''
        ${pkgs.restic}/bin/restic snapshots &>/dev/null || ${pkgs.restic}/bin/restic init

        ${pkgs.restic}/bin/restic backup $HOME \
          --exclude-file=${homeDirectory}/.config/restic/excludes.txt \
          --verbose

        ${pkgs.restic}/bin/restic forget \
          --keep-daily 7 \
          --keep-weekly 4 \
          --keep-monthly 6 \
          --prune
        
        CURRENT_HOUR=$(date +%-H)
        if [ "$CURRENT_HOUR" -ge 3 ] && [ "$CURRENT_HOUR" -lt 6 ]; then
          systemctl suspend
        fi
      ''}";
      Restart = "on-failure";
      RestartSec = "1m";
    };
  };

  home.file."drive/.keep".text = "";

  systemd.user.services.rclone-mount = {
    Unit = {
      Description = "Montagem do Google Drive via Rclone";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
      Before = [ "sleep.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount p052:root %h/drive \
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

  age.secrets = {
    rclone = {
      file = "${homeDirectory}/.nix-config/secrets/rclone.age";
      path = "${homeDirectory}/.config/rclone/rclone.conf";
      mode = "0600";
    };
    
    restic-password = {
      file = "${homeDirectory}/.nix-config/secrets/restic.age";
      path = "${homeDirectory}/.secrets/restic";
      mode = "0600";
    };
  };
}
