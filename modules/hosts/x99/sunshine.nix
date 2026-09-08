{ config, pkgs, ... }:

{
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
    applications = [
      {
        name = "Desktop";
        image-path = "desktop.png";
      }
    ];
  };

  hardware.uinput.enable = true;
  users.users."user".extraGroups = [ "uinput" ];

  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };

  networking.firewall = {
    allowedTCPPortRanges = [
      { from = 47984; to = 48010; }
    ];
    allowedUDPPortRanges = [
      { from = 47998; to = 48010; }
    ];
  };
}
