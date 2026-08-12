{
  lib,
  pkgs,
  ...
}:
lib.mkIf pkgs.stdenv.isLinux {
  home.packages = with pkgs; [
    umu-launcher
    protonup-qt
    protontricks
    winetricks
  ];
}
