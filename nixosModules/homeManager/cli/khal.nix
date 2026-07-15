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

  home.activation.setupVdirsyncerDir = config.lib.dag.entryBefore [ "checkLinkTargets" ] ''
    mkdir -p "${config.home.homeDirectory}/.config/vdirsyncer"
  '';

  home.file.".config/khal/config".text = ''
    [calendars]

    [[unicamp]]
    path = /home/user/.ics/unicamp/*
    type = discover

    [default]
    default_calendar = p322814@dac.unicamp.br

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
    };
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "vdirsyncer-init-script" ''
        timeout=30
        while [ ! -f "${config.home.homeDirectory}/.config/vdirsyncer/config" ] && [ $timeout -gt 0 ]; do
          sleep 1
          timeout=$((timeout - 1))
        done

        if [ ! -d "${config.home.homeDirectory}/.ics/unicamp" ]; then
          mkdir -p "${config.home.homeDirectory}/.ics/unicamp"
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
