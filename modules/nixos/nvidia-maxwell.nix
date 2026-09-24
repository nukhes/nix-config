_:

{
  nixos.modules.x99 = { config, pkgs, ... }: {
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware = {
      graphics = {
        enable = true;
        extraPackages = with pkgs; [
          nvidia-vaapi-driver
        ];
      };

      nvidia = {
        package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
        modesetting.enable = true;
        powerManagement.enable = false;
        powerManagement.finegrained = false;
        nvidiaSettings = true;
        open = false;
      };
    };

    boot.kernelParams = [ 
      "pcie_aspm=off" 
      "nvidia.NVreg_EnableGpuFirmware=0" 
    ];

    boot.extraModprobeConfig = ''
      options nvidia NVreg_RegistryDwords="PowerMizerEnable=0x1; PerfLevelSrc=0x2222; PowerMizerLevel=0x1; PowerMizerDefault=0x1; PowerMizerDefaultAC=0x1"
    '';

    environment = {
      variables = {
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      };

      systemPackages = with pkgs; [
        nvtopPackages.nvidia
        mesa-demos
        vulkan-tools
      ];
    };
  };
}
