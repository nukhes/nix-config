{ config, pkgs, lib, ... }:
let
  rcloneSyncs = [
    {
      name = "uni";
      remote = "p322814:uni";
      local = "${config.home.homeDirectory}/uni";
    }
    {
      name = "usr";
      remote = "p052:/";
      local = "${config.home.homeDirectory}/usr";
    }
    {
      name = "library";
      remote = "p322814:library";
      local = "${config.home.homeDirectory}/.local/share/calibre-library";
    }
  ];

  rclone = "${pkgs.rclone}/bin/rclone";
  rcloneFlags = "--config ${config.age.secrets.rclone.path} --log-level INFO --timeout 5m --transfers 4";

  createRcloneSync = { remote, local }: {
    Unit = {
      Description = "Sync rclone for ${local}";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      
      ExecStartPre = [
        "${pkgs.bash}/bin/bash"
        "-c"
        ''
        if [ ! -d "${local}" ] || [ -z "$(ls -A "${local}" 2>/dev/null)" ]; then
          echo "pulling from ${remote}..."
          ${rclone} copy "${remote}" "${local}" ${rcloneFlags}
        fi
        ''
      ];

      ExecStart = ''
        ${rclone} copy "${local}" "${remote}" ${rcloneFlags}
      '';
      
      Nice = 19;
    };
  };

  createRcloneTimer = { name }: {
    Unit.Description = "Timer for rclone sync ${name}";
    Timer = {
      OnCalendar = "hourly";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  servicesAttrs = lib.listToAttrs (map (sync: {
    name = "rclone-sync-${sync.name}";
    value = createRcloneSync { remote = sync.remote; local = sync.local; };
  }) rcloneSyncs);

  timersAttrs = lib.listToAttrs (map (sync: {
    name = "rclone-sync-${sync.name}";
    value = createRcloneTimer { name = sync.name; };
  }) rcloneSyncs);
in
{
  home.packages = [ pkgs.rclone ];

  systemd.user.services = servicesAttrs;
  systemd.user.timers = timersAttrs;

  age.secrets.rclone = {
    file = "${config.home.homeDirectory}/.nix-config/secrets/rclone.age";
    path = "${config.home.homeDirectory}/.config/rclone/rclone.conf";
    mode = "0600";
  };
}

