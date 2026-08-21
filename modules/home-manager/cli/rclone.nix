{
  config,
  pkgs,
  ...
}:

let
  inherit (config.home) homeDirectory;
in
{
  home.packages = with pkgs; [ rclone ];

  xdg.configFile."rclone/filter.txt".text = ''
    - /.cache/**
    - /.local/share/Trash/**
    - /.thumbnails/**
    - /.var/app/**/cache/**
    - /.npm/**
    - /projects/**
    - /.var/app/**/.cache/**
    - /.config/**/Cache/**
    - /.config/**/cache/**
    - /.config/**/GPUCache/**
    - /.config/**/Code Cache/**
    - /.config/**/Crash Reports/**
    - /.config/**/Crashpad/**
    - /.config/**/Session Storage/**
    - /.config/**/Service Worker/CacheStorage/**
    - /.mozilla/firefox/**/cache2/**
    - /.mozilla/firefox/**/startupCache/**
  '';

  systemd.user.services.rclone-backup = {
    Unit = {
      Description = "Rclone backup to Google Drive";
      After = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "rclone-backup-run" ''
        ${pkgs.rclone}/bin/rclone copy $HOME/ p052:backup/hackbook/home --filter-from $HOME/.config/rclone/filter.txt -P --transfers=8 --drive-chunk-size=64M --retries 5 --retries-sleep 10s --low-level-retries 10
        CURRENT_HOUR=$(date +%-H)
        if [ "$CURRENT_HOUR" -ge 3 ] && [ "$CURRENT_HOUR" -lt 6 ]; then
          systemctl suspend
        fi
      ''}";
      Restart = "on-failure";
      RestartSec = "1m";
    };
  };

  systemd.user.timers.rclone-backup = {
    Unit = {
      Description = "Timer for rclone backup";
    };
    Timer = {
      OnCalendar = "*-*-* 03:00:00";
      Persistent = true;
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  age.secrets.rclone = {
    file = "${homeDirectory}/.nix-config/secrets/rclone.age";
    path = "${homeDirectory}/.config/rclone/rclone.conf";
    mode = "0600";
  };
}
