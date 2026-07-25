{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf pkgs.stdenv.isLinux {
  imports = [
    ./cursor.nix
    ./i3.nix
    ./picom.nix
    ./polybar.nix
    ./redshift.nix
    ./rofi.nix
    ./theme.nix
    ./xdg.nix
  ];
}
