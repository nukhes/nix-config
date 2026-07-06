{
  config,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    khal
    vdirsyncer
  ];

  home.file.".config/khal/config".text = ''
      [calendars]

      [[unicamp]]
      path = /home/user/.ics/unicamp/

      [locale]
      local_timezone= America/Sao_Paulo
      default_timezone= America/Sao_Paulo
      timeformat = %H:%M
      dateformat = %d/%m/%Y
      longdateformat = %d/%m/%Y
  '';

  services.vdirsyncer.enable = true;

  systemd.user.services."vdirsyncer-init" = {
    Unit = {
      Description = "vdirsyncer first sync";
      After = [ "agenix.service" ]; 
    };
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "vdirsyncer-init-script" ''
        if [ ! -d "${config.home.homeDirectory}/.ics" ]; then
          mkdir -p ${config.home.homeDirectory}/.ics/unicamp
        fi
        yes | ${pkgs.vdirsyncer}/bin/vdirsyncer discover unicamp_sync || true
      '';
      RemainAfterExit = true;
    };
    Install.WantedBy = [ "default.target" ];
  };

  age.secrets.vdirsyncer = {
    file = ../../secrets/vdirsyncer.age;
    path = "${config.home.homeDirectory}/.config/vdirsyncer/config";
    mode = "0600";
  };
}
