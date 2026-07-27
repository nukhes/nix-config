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
    ./picom.nix
    ./polybar.nix
    ./redshift.nix
    ./rofi.nix
    ./theme.nix
    ./xdg.nix
  ];

  options.modules.desktop.enable = lib.mkOption {
    type = lib.types.bool;
    default = !pkgs.stdenv.isDarwin;
    description = "i3wm desktop";
  };
}
