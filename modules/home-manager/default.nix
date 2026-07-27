{
  config,
  lib,
  pkgs ? null,
  ...
}:
let
  common = [ ./cli ./programs ];
  linuxDesktop = [ ./desktop  ];
in
{
  home.username = "user";
  home.stateVersion = "26.05";
  home.homeDirectory = lib.mkForce "/home/user";
  imports = common ++ lib.optionals (pkgs != null) linuxDesktop;
}
