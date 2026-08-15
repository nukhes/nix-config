{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (pkgs.stdenv) isDarwin isLinux;
  inherit (config.home) homeDirectory;
  inherit (config.xdg) configHome;

  cfgDir = "${configHome}/vdirsyncer";
  cfgFile = "${cfgDir}/config";
  calDir = "${homeDirectory}/.ics/unicamp";

  initScript = pkgs.writeShellScript "vdirsyncer-init-script" ''
    timeout=30
    while [ ! -f "${cfgFile}" ] && [ $timeout -gt 0 ]; do
      sleep 1
      timeout=$((timeout - 1))
    done

    if [ ! -f "${cfgFile}" ]; then
      exit 1
    fi

    mkdir -p "${calDir}"

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
    file = "${homeDirectory}/.nix-config/secrets/vdirsyncer.age";
    path = cfgFile;
    mode = "0600";
  };

  services.vdirsyncer = lib.mkIf isLinux {
    enable = true;
    frequency = "*:0/30";
  };

  systemd.user.services."vdirsyncer-init" = lib.mkIf isLinux {
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

  launchd.agents = lib.mkIf isDarwin {
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
        StartInterval = 1800;
        RunAtLoad = true;
      };
    };
  };
}
