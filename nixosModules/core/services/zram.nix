{
  config,
  pkgs,
  lib,
  ...
}:
{
  zramSwap = {
    enable = true;
    priority = 100;
    algorithm = "zstd";
    memoryPercent = 70;
  };
}
