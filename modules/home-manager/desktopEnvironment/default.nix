{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./cursor.nix
    ./i3.nix
    ./polybar.nix
    ./redshift.nix
    ./rofi.nix
    ./theme.nix
    ./xdg.nix
    ./picom.nix
  ];
}
