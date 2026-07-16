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
    "acpi_osi=Darwin"
    "intel_pstate=passive"
    "pcie_aspm=force"
    "lsm=capability,yama"
    "mem_sleep_default=s2idle"
    "thermal.nocrt=1"
    "processor.ignore_ppc=1"
    # Habilitar escrita em MSR permite acesso a registradores model-specific —
    # é um risco de segurança; deixe apenas se for necessário para hardware.
    "msr.allow_writes=on"
  ];

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
