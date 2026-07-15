{
  config,
  pkgs,
  ...
}:
let
  createRcloneMount =
    {
      name,
      remote,
      mountPoint,
      cacheSize,
    }:
    {
      Unit = {
        Description = "Rclone VFS Mount for ${name}";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };

      Service = {
        Type = "notify";

        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${mountPoint}";

        ExecStart = ''
          ${pkgs.rclone}/bin/rclone mount ${remote} ${mountPoint} \
            --vfs-cache-mode full \
            --vfs-read-chunk-size 16M \
            --vfs-read-chunk-size-limit 1G \
            --vfs-read-wait 20ms \
            --no-check-certificate \
            --dir-cache-time 72h \
            --attr-timeout 72h \
            --vfs-cache-max-size ${cacheSize} \
            --vfs-cache-max-age 999h \
            --log-level INFO
        '';
        ExecStop = "${pkgs.fuse}/bin/fusermount -uz ${mountPoint}";

        Restart = "on-failure";
        RestartSec = "10s";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
in
{
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
    file = ../../../secrets/rclone.age;
    path = "${config.home.homeDirectory}/.config/rclone/rclone.conf";
    mode = "0600";
  };
}
