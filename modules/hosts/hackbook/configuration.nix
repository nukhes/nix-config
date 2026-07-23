{ config, pkgs, lib, inputs, modules, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./broadcom.nix

    "${modules}/nixos/boot.nix"
    "${modules}/nixos/desktop.nix"
    "${modules}/nixos/flatpak.nix"
    "${modules}/nixos/gaming.nix"
    "${modules}/nixos/laptop.nix"
    "${modules}/nixos/locale.nix"
    "${modules}/nixos/networking.nix"
    "${modules}/nixos/services.nix"
    "${modules}/nixos/zram.nix"
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.user = {
      imports = [
        inputs.agenix.homeManagerModules.default
        "${modules}/home-manager/"
      ];
    };
    backupFileExtension = "backup";
  };

  system.stateVersion = "26.05";
}
