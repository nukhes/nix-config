{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    # ./hardware-configuration.nix
    ./../../modules/core
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.config.allowUnfree = true;

  networking.hostName = "desktop";

  boot.kernelParams = [
    "nowatchdog"
    "nmi_watchdog=0"
    "audit=0"
    "transparent_hugepage=always"
    "mitigations=off"
  ];

  zramSwap = {
    enable = true;
    priority = 100;
    algorithm = "zstd";
    memoryPercent = 50;
  };

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
