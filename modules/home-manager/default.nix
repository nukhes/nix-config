{
  config,
  lib,
  pkgs,
  agenixModule,
  ...
}:
{
  home.username = "user";
  home.stateVersion = "26.05";
  home.homeDirectory = lib.mkForce "/home/user";

  imports = [
    ./cli

  # desktopEnvironment and programs are deeply tied with Linux
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    ./desktopEnvironment
    ./programs
  ];
}
