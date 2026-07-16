{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./cli
    ./desktopEnvironment
    ./programs
  ];
}
