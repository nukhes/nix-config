{
  modules,
  ...
}:

{
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
  hardware.cpu.intel.updateMicrocode = false;
  boot.kernelParams = [ "nvidia-drm.modeset=1" ];
  system.stateVersion = "26.05";
}
