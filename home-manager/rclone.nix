{
  config,
  pkgs,
  ...
}: let
  rclone-sync-script = pkgs.writeShellScriptBin "rclone-sync-engine" ''
    rcsync() {
      local dir="$1"
      local remote="$2"
      mkdir -p "$dir"
      if [ -z "$(ls -A "$dir")" ]; then
        echo "[!] pulling data from remote..."
        ${pkgs.rclone}/bin/rclone copy "$remote" "$dir" --progress --create-empty-src-dirs
        ${pkgs.rclone}/bin/rclone bisync "$dir" "$remote" --progress --resync --create-empty-src-dirs
      else
        echo "[*] starting bidirectional sync..."
        ${pkgs.rclone}/bin/rclone bisync "$dir" "$remote" --progress --create-empty-src-dirs
      fi
    }

    rcsync "${config.home.homeDirectory}/geo/" p322814: && rcsync "${config.home.homeDirectory}/usr/" p052:
  '';
in {
  home.packages = [rclone-sync-script];

  systemd.user.services.rclone-automation = {
    Unit = {
      Description = "Sync my files in Google Drive";
      After = ["network-online.target"];
      Wants = ["network-online.target"];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${rclone-sync-script}/bin/rclone-sync-engine";
    };
  };

  systemd.user.timers.rclone-automation = {
    Unit = {
      Description = "Timer for auto run service";
    };

    Timer = {
      OnBootSec = "5m";
      OnUnitActiveSec = "30m";
      Persistent = true;
    };

    Install = {
      WantedBy = ["timers.target"];
    };
  };

  age.secrets.rclone = {
    file = ../secrets/rclone.age;
    path = "${config.home.homeDirectory}/.config/rclone/rclone.conf";
    mode = "0600";
  };
}
