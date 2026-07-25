{
  config,
  lib,
  pkgs ? null,
  ...
}:
let
  baseImports = [ ./cli ];
  pkgsImports = [ ./desktopEnvironment ./programs ];
in
{
  home.username = "user";
  home.stateVersion = "26.05";
  home.homeDirectory = lib.mkForce "/home/user";

  imports = baseImports ++ lib.optionals (pkgs != null) pkgsImports;
}
