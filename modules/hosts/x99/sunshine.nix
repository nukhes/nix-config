{ config, pkgs, ... }:

{
  # Sunshine - Game Streaming Server (NVIDIA NVENC optimized)
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
    package = pkgs.sunshine.override {
      cudaSupport = true;
    };
    settings = {
      encoder = "nvenc";
      min_fps_factor = 1;
      min_threads = 2;
    };
    applications = {
      apps = [
        {
          name = "Desktop";
          image-path = "desktop.png";
        }
        {
          name = "Steam Big Picture";
          detached = [
            "${pkgs.util-linux}/bin/setsid ${pkgs.steam}/bin/steam steam://open/bigpicture"
          ];
          image-path = "steam.png";
        }
      ];
    };
  };

  # uinput for virtual input devices (mouse/keyboard emulation)
  hardware.uinput.enable = true;
  users.users."user".extraGroups = [ "uinput" ];

  # Avahi for auto-discovery on local network
  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };

  # Firewall: Sunshine uses UDP for streaming
  networking.firewall = {
    allowedTCPPortRanges = [
      { from = 47984; to = 48010; }
    ];
    allowedUDPPortRanges = [
      { from = 47998; to = 48010; }
    ];
  };
}
