{
  config,
  pkgs,
  ...
}: let
  # Reusable function to generate systemd mount services
  createRcloneMount = { name, remote, mountPoint, cacheSize }: {
    Unit = {
      Description = "Rclone VFS Mount for ${name}";
      After = ["network-online.target"];
      Wants = ["network-online.target"];
    };

    Service = {
      # "notify" tells systemd to wait until rclone signals it has successfully mounted
      Type = "notify";
      
      # Ensure the mount point exists before starting
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${mountPoint}";
      
      # The core mount command
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount ${remote} ${mountPoint} \
          --vfs-cache-mode full \
          --vfs-cache-max-size ${cacheSize} \
          --vfs-cache-max-age 48h \
          --dir-cache-time 1h \
          --log-level INFO
      '';

      # Let systemd automatically restart the mount if the network drops and it crashes
      Restart = "on-failure";
      RestartSec = "10s";
    };

    Install = {
      WantedBy = ["default.target"];
    };
  };

in {
  home.packages = [
    pkgs.rclone
    pkgs.rsync
    pkgs.fuse 
  ];

  systemd.user.services.rclone-mount-geo = createRcloneMount {
    name = "geo";
    remote = "p322814:home/geo";
    mountPoint = "${config.home.homeDirectory}/geo";
    cacheSize = "30G";
  };

  systemd.user.services.rclone-mount-usr = createRcloneMount {
    name = "usr";
    remote = "p052:home/usr";
    mountPoint = "${config.home.homeDirectory}/usr";
    cacheSize = "30G";
  };

  age.secrets.rclone = {
    file = ../secrets/rclone.age;
    path = "${config.home.homeDirectory}/.config/rclone/rclone.conf";
    mode = "0600";
  };
}