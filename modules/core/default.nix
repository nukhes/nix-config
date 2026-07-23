{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./desktop.nix
    ./flatpak.nix
    ./gaming.nix
    ./services.nix
    ./system.nix
  ];
}
