{
  config,
  pkgs,
  lib,
  inputs,
  modules,
  secrets,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./broadcom.nix
    "${modules}/nixos"
    "${modules}/nixos/laptop.nix"
    "${modules}/nixos/networking.nix"
  ];

  systemd.timers.wake-system-backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 03:00:00";
      WakeSystem = true;
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    backupFileExtension = "backup";
    overwriteBackup = true;
    users.user = {
      imports = [
        inputs.agenix.homeManagerModules.default
        "${modules}/home-manager/"
      ];
    };
  };

  boot.kernel.sysctl = {
    "fs.file-max" = 2097152;
    "fs.inotify.max_user_watches" = 524288;
  };

  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "524288";
    }
    {
      domain = "*";
      type = "hard";
      item = "nofile";
      value = "1048576";
    }
  ];

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  hardware.bluetooth.settings = {
    General = {
      Experimental = true;
      FastConnectable = true;
    };
  };
  services.blueman.enable = true;

  system.stateVersion = "26.05";
}
