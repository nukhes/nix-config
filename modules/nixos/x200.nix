_:

{
  nixos.modules.x200 =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [
        ./x200-hardware.pkg.nix
      ];

      networking = {
        hostName = "x200";
        networkmanager = {
          enable = true;
          wifi.powersave = true;
        };
      };

      hardware.enableRedistributableFirmware = true;
      hardware.cpu.intel.updateMicrocode = true;

      # -- Intel GMA 4500MHD (GM45) graphics --
      hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [
          intel-vaapi-driver # VA-API hw video decode
          libvdpau-va-gl
        ];
      };

      environment.variables = {
        LIBVA_DRIVER_NAME = "i965"; # legacy driver for pre-HD Intel GPUs
      };

      # -- ThinkPad thermal management --
      services.thermald.enable = true;

      # -- ThinkPad fan control via thinkfan --
      services.thinkfan = {
        enable = true;
        levels = [
          [ 0  0   42 ]
          [ 1  40  47 ]
          [ 2  45  52 ]
          [ 3  50  57 ]
          [ 4  55  62 ]
          [ 5  60  67 ]
          [ 7  65  80 ]
          [ "level auto" 77 32767 ]
        ];
      };

      # -- zram swap: essential on a low-RAM machine --
      zramSwap = {
        enable = true;
        priority = 100;
        algorithm = "lz4"; # lighter than zstd for Core 2 Duo
        memoryPercent = 75;
      };

      # -- Limit nix build concurrency to avoid OOM --
      nix.settings = {
        max-jobs = 1;
        cores = 2;
      };

      # -- Disable unnecessary overhead --
      security.audit.enable = false;
      security.auditd.enable = false;

      # -- Lightweight journald to save disk I/O --
      services.journald.extraConfig = ''
        Storage=volatile
        RuntimeMaxUse=4M
        RuntimeMaxFileSize=256K
        MaxLevelStore=warning
        MaxLevelSyslog=warning
        MaxLevelKMsg=warning
        MaxLevelConsole=warning
        MaxLevelWall=crit
        Compress=yes
        ForwardToSyslog=no
        ForwardToKMsg=no
        ForwardToConsole=no
        ForwardToWall=no
      '';

      # -- PowerTop auto-tune on boot --
      systemd.services.powertop-autotune = {
        description = "PowerTop auto-tune for maximum power savings";
        after = [ "multi-user.target" ];
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.powertop ];
        script = ''
          powertop --auto-tune
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };

      # -- Disable suspend/hibernate targets (optional, enable if you want them) --
      # ThinkPad X200 has known quirks with S3 sleep; leave enabled but deep mode
      services.logind = {
        lidSwitch = "suspend";
        lidSwitchExternalPower = "lock";
      };

      system.stateVersion = "26.05";
    };
}
