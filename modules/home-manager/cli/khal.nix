{ config, pkgs, lib, ... }:

let
  # Create a reusable initialization shell script for both OS daemons
  initScript = pkgs.writeShellScript "vdirsyncer-init-script" ''
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
in
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
    path = ${config.home.homeDirectory}/.ics/unicamp/*
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

  age.secrets.vdirsyncer = {
    file = "${config.home.homeDirectory}/.nix-config/secrets/vdirsyncer.age";
    path = "${config.home.homeDirectory}/.config/vdirsyncer/config";
    mode = "0600";
  };

  # Linux Systemd
  services.vdirsyncer.enable = lib.mkIf pkgs.stdenv.isLinux true;

  systemd.user.services."vdirsyncer-init" = lib.mkIf pkgs.stdenv.isLinux {
    Unit = { Description = "vdirsyncer first sync"; };
    Service = {
      Type = "oneshot";
      ExecStart = initScript;
      RemainAfterExit = true;
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Darwin Service with Launchd
  launchd.agents = lib.mkIf pkgs.stdenv.isDarwin {
    "vdirsyncer-init" = {
      enable = true;
      config = {
        ProgramArguments = [ "${initScript}" ];
        RunAtLoad = true;
      };
    };

    "vdirsyncer-sync" = {
      enable = true;
      config = {
        ProgramArguments = [ "${pkgs.vdirsyncer}/bin/vdirsyncer" "sync" ];
        StartInterval = 300; # 300 seconds = 5 minutes
        RunAtLoad = false;
      };
    };
  };
}