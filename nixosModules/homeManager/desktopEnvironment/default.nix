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
    ./redshift.nix
    ./theme.nix
    ./xdg.nix
  ];
}
