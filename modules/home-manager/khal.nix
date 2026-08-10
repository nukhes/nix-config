{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfgDir = "${config.xdg.configHome}/vdirsyncer";
  cfgFile = "${cfgDir}/config";
  calDir = "${config.home.homeDirectory}/.ics/unicamp";

  # Create a reusable initialization shell script for both OS daemons
  initScript = pkgs.writeShellScript "vdirsyncer-init-script" ''
    timeout=30
    while [ ! -f "${cfgFile}" ] && [ $timeout -gt 0 ]; do
      sleep 1
      timeout=$((timeout - 1))
    done

    if [ ! -f "${cfgFile}" ]; then
      echo "Timeout waiting for vdirsyncer config file."
      exit 1
    fi

    # Ensure the calendar directory exists safely
    mkdir -p "${calDir}"

    # Discover without blocking or exiting with error
    yes | ${pkgs.vdirsyncer}/bin/vdirsyncer discover unicamp_sync || true
  '';
in
{
  home.packages = with pkgs; [
    khal
    vdirsyncer
  ];

  home.activation.setupVdirsyncerDir = config.lib.dag.entryBefore [ "checkLinkTargets" ] ''
    mkdir -p "${cfgDir}"
  '';

  xdg.configFile."khal/config".text = ''
    [calendars]

    [[unicamp]]
    path = ${calDir}/*
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
    path = cfgFile;
    mode = "0600";
  };

  # Linux Systemd
  services.vdirsyncer = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    frequency = "*:0/30";
  };

  systemd.user.services."vdirsyncer-init" = lib.mkIf pkgs.stdenv.isLinux {
    Unit = {
      Description = "vdirsyncer first sync";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${initScript}";
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
        ProgramArguments = [
          "${pkgs.vdirsyncer}/bin/vdirsyncer"
          "sync"
        ];
        StartInterval = 1800; # 1800 seconds = 30 minutes
        RunAtLoad = true;
      };
    };
  };
}
