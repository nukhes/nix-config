{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.packages = with pkgs; [
    umu-launcher
    protonup-qt
    protontricks
    winetricks
  ];
}
