{ pkgs, ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_6_18;
  boot.kernelParams = [
    "nowatchdog"
    "nmi_watchdog=0"
    "audit=0"
    "transparent_hugepage=always"
    "mitigations=off"
  ];
}
