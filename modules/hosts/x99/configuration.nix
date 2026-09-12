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

  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
  services.logind.settings = {
    IdleAction = "ignore";
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };

  networking = {
    hostName = "x99";
    networkmanager.enable = true;
  };

  boot.kernelModules = [ 
    "coretemp"
    "nct6775"
    
  ];

  boot.blacklistedKernelModules = [
    "firewire-core"
    "mei_me"
    "mei"
    "lpc_ich"
    "ieee1394"
    "sbp2"
  ];

  powerManagement.cpuFreqGovernor = "performance";
  hardware.cpu.intel.updateMicrocode = false;
  boot.kernelParams = [ "nvidia-drm.modeset=1" ];
  system.stateVersion = "26.05";
}
