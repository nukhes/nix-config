{ ... }:

{
  nixos.modules.x99 = { ... }: {
    imports = [
      ./x99-hardware.pkg.nix
    ];

    systemd.targets = {
      sleep.enable = false;
      suspend.enable = false;
      hibernate.enable = false;
      hybrid-sleep.enable = false;
    };

    networking = {
      hostName = "x99";
      networkmanager.enable = true;
    };

    services.libinput = {
      enable = true;
      mouse.accelProfile = "flat";
      touchpad.accelProfile = "flat";
    };

    boot = {
      kernelModules = [
        "coretemp"
        "nct6775"
      ];
      blacklistedKernelModules = [
        "firewire-core"
        "mei_me"
        "mei"
        "lpc_ich"
        "ieee1394"
        "sbp2"
      ];
      kernelParams = [ "nvidia-drm.modeset=1" ];
    };

    powerManagement.cpuFreqGovernor = "ondemand";
    hardware.cpu.intel.updateMicrocode = false;
    system.stateVersion = "26.05";
  };
}
