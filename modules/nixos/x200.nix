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

      hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [
          intel-vaapi-driver
          libvdpau-va-gl
        ];
      };

      environment.variables = {
        LIBVA_DRIVER_NAME = "i965"; # legacy driver for pre-HD Intel GPUs
      };

      services.thermald.enable = true;

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

      zramSwap = {
        enable = true;
        priority = 100;
        algorithm = "lz4"; # lighter than zstd for Core 2 Duo
        memoryPercent = 75;
      };

      nix.settings = {
        max-jobs = 1;
        cores = 2;
      };

      security.audit.enable = false;
      security.auditd.enable = false;

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

      services.logind.settings.Login = {
        HandleLidSwitch = "suspend";
        HandleLidSwitchExternalPower = "lock";
      };

      system.stateVersion = "26.05";
    };
}
