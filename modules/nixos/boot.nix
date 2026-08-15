{ pkgs, ... }:
{
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_6_18;
    kernelParams = [
      "nowatchdog"
      "nmi_watchdog=0"
      "audit=0"
      "transparent_hugepage=always"
      "mitigations=off"
    ];
  };
}
