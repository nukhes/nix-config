{ config, pkgs, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.legacy_535;
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    nvidiaSettings = true;
    open = false;
  };

  hardware.graphics.extraPackages = with pkgs; [
    nvidia-vaapi-driver
  ];

  environment.variables = {
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  environment.systemPackages = with pkgs; [
    nvtopPackages.nvidia
    mesa-demos
    vulkan-tools
  ];
}
