{ modules, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./nvidia.nix
    ./sunshine.nix
    "${modules}/nixos"
  ];

  networking = {
    hostName = "x99";
    networkmanager.enable = true;
  };

  powerManagement.cpuFreqGovernor = "performance";

  boot.kernel.sysctl."vm.swappiness" = 10;

  system.stateVersion = "26.05";
}
