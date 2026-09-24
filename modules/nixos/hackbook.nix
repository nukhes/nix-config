_:

{
  nixos.modules.hackbook =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [
        ./hackbook-hardware.pkg.nix
      ];

      networking = {
        hostName = "hackbook";
        networkmanager = {
          enable = true;
          wifi.powersave = false;
        };
      };

      hardware.enableRedistributableFirmware = true;

      environment.systemPackages = [ pkgs.moonlight-qt ];

      services.mbpfan = {
        enable = true;
        settings = {
          general.polling_interval = 5;
          info = {
            min_fan_speed = 2000;
            max_fan_speed = 6200;
            low_temp = 55;
            high_temp = 65;
            max_temp = 75;
          };
        };
      };

      systemd.services.disable-prochot = {
        description = "Disable BD_PROCHOT and apply PowerTop auto-tune";
        after = [ "systemd-modules-load.service" ];
        wantedBy = [ "multi-user.target" ];
        path = with pkgs; [
          msr-tools
          powertop
        ];
        script = ''
          powertop --auto-tune
          wrmsr -a 0x1FC 0x4005a
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };

      zramSwap = {
        enable = true;
        priority = 100;
        algorithm = "zstd";
        memoryPercent = 80;
      };

      nix.settings = {
        max-jobs = 1;
        cores = 1;
      };

      security.audit.enable = false;
      security.auditd.enable = false;

      services.journald.extraConfig = ''
        Storage=volatile
        RuntimeMaxUse=1M
        RuntimeMaxFileSize=128K
        MaxLevelStore=crit
        MaxLevelSyslog=crit
        MaxLevelKMsg=crit
        MaxLevelConsole=crit
        MaxLevelWall=crit
        Compress=no
        ForwardToSyslog=no
        ForwardToKMsg=no
        ForwardToConsole=no
        ForwardToWall=no
      '';

      system.stateVersion = "26.05";
    };
}
