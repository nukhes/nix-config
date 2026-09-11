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
  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642;
    "fs.file-max" = 2097152;
  };


  boot.kernelParams = [ "nvidia-drm.modeset=1" ];

  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "524288";
    }
    {
      domain = "*";
      type = "hard";
      item = "nofile";
      value = "1048576";
    }
  ];

  system.stateVersion = "26.05";
}
