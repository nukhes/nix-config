{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
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
    "acpi_osi=!Darwin"
    "intel_pstate=passive"
    "pcie_aspm=force"
    "lsm=capability,yama"
    "mem_sleep_default=s2idle"
    "nowatchdog"
    "nmi_watchdog=0"
    "audit=0"
    "transparent_hugepage=always"
    "thermal.nocrt=1"
    "processor.ignore_ppc=1"
    "msr.allow_writes=on"
    "mitigations=off"
  ];

  boot.kernel.sysctl = {
    "kernel.core_pattern" = "|/bin/false";
    "net.ipv4.tcp_timestamps" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "vm.dirty_background_ratio" = 60;
    "vm.dirty_ratio" = 80;
    "vm.dirty_expire_centisecs" = 60000;
    "vm.dirty_writeback_centisecs" = 60000;
    "vm.swappiness" = 180;
    "kernel.sched_min_granularity_ns" = 100000;
    "kernel.sched_wakeup_granularity_ns" = 100000;
    "kernel.sched_migration_cost_ns" = 0;
  };

  networking.networkmanager.wifi.powersave = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  nixpkgs.config.allowInsecurePredicate = pkg: (builtins.elem (lib.getName pkg) [ "broadcom-sta" ]);

  boot.kernelModules = [ "wl" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  boot.blacklistedKernelModules = [
    "b43"
    "bcma"
    "ssb"
    "brcmsmac"
    "intel_pch_thermal"
    "intel_rapl_msr"
    "intel_rapl_common"
    "intel_powerclamp"
    "thunderbolt"
  ];

  nixpkgs.overlays = [
    (final: prev: {
      nur = import inputs.nur {
        nurpkgs = prev;
        pkgs = prev;
      };
    })
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.user = {
      imports = [
        inputs.agenix.homeManagerModules.default
        ./../../home.nix
      ];
    };
    backupFileExtension = "backup";
  };

  system.stateVersion = "26.05";
}
