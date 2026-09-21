{ pkgs, ... }
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

    # Fix Arzopa monitor crash
    services.xserver.displayManager.setupCommands = let
      xrandr = "${pkgs.xorg.xrandr}/bin/xrandr";
    in ''
      if ! ${xrandr} | grep -q "1920x1080_rb"; then
        ${xrandr} --newmode "1920x1080_rb" 138.50 1920 1968 2000 2080 1080 1083 1088 1111 +hsync -vsync
        ${xrandr} --addmode HDMI-0 "1920x1080_rb"
      fi
      ${xrandr} --output HDMI-0 --mode "1920x1080_rb"
    '';

    powerManagement.cpuFreqGovernor = "ondemand";
    hardware.cpu.intel.updateMicrocode = false;
    system.stateVersion = "26.05";
  };
}
