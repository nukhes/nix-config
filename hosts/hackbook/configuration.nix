{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./../../nixosModules/services
    ./../../nixosModules/programs
    ./../../nixosModules/core
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.config.allowUnfree = true;

  networking.hostName = "hackbook";

  boot.kernelParams = [
    "i915.enable_fbc=1"
    "i915.enable_guc=3"
    "acpi_osi=Darwin"
    "intel_pstate=disable"
    "pcie_aspm=force"
    "mem_sleep_default=s2idle"
  ];

  zramSwap = {
    enable = true;
    priority = 100;
    algorithm = "zstd";
    memoryPercent = 60;
  };

  networking.networkmanager.wifi.powersave = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  services.thermald.enable = true;
  services.throttled = {
    enable = true;
    extraConfig = ''
      [AC]
      BDPROCHOT = False

      [BATTERY]
      BDPROCHOT = False
    '';
  };

  nixpkgs.config.allowInsecurePredicate = pkg: (builtins.elem (lib.getName pkg) [ "broadcom-sta" ]);

  boot.kernelModules = [ "wl" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  boot.blacklistedKernelModules = [
    "b43"
    "bcma"
    "ssb"
    "brcmsmac"
  ];

  system.stateVersion = "26.05";
}
