{ config, pkgs, ... }:

let
  flakeConfig = config;
in
{
  nixos.modules.x99 =
    { ... }:
    {
      imports = [
        ./x99-hardware.pkg.nix
      ];

      home-manager.users.user.imports = [
        flakeConfig.hm.modules.x99
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

      # Fix Arzopa monitor crash
      services.xserver.displayManager.setupCommands =
        let
          xrandr = "${pkgs.xorg.xrandr}/bin/xrandr";
        in
        ''
          if ! ${xrandr} | grep -q "1920x1080_rb"; then
            ${xrandr} --newmode "1920x1080_rb" 138.50 1920 1968 2000 2080 1080 1083 1088 1111 +hsync -vsync
            ${xrandr} --addmode HDMI-0 "1920x1080_rb"
          fi
          ${xrandr} --output HDMI-0 --mode "1920x1080_rb"
        '';

      powerManagement.cpuFreqGovernor = "performance";

      # Prevent audio device power saving (fixes crackling/popping)
      boot.extraModprobeConfig = ''
        options snd_hda_intel power_save=0 power_save_controller=N
        options snd_usb_audio nrpacks=1
      '';

      hardware.cpu.intel.updateMicrocode = false;

      # Swap configuration: zram for fast compressed in-memory swap, backed by swapfile on NVMe
      zramSwap = {
        enable = true;
        priority = 100;
        algorithm = "zstd";
        memoryPercent = 50;
      };

      swapDevices = [
        {
          device = "/var/lib/swapfile";
          size = 16384;
          priority = 10;
        }
      ];

      system.stateVersion = "26.05";
    };
}
