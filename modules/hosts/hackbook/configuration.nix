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
