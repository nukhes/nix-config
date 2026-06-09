{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../common/desktop.nix
    ../common/cli-tools.nix
    ../common/pipewire.nix
    ../common/eduroam.nix
    ../common/wacom.nix
    ../common/tlp.nix
  ];

  networking.hostName = "hackbook";

  # System Tweaks
  boot.kernelParams = [
    "i915.enable_fbc=1"
    "i915.enable_guc=3"
    "acpi_osi=Darwin"
    "acpi_mask_gpe=0x17"
    "pcie_aspm=force"
  ];
  zramSwap = {
    enable = true;
    priority = 100;
    algorithm = "zstd";
    memoryPercent = 100;
  };
  # End System Tweaks

  # Broadcom Wifi Chip
  networking.wireless.enable = true;
  nixpkgs.config.permittedInsecurePackages = [
    "broadcom-sta-6.30.223.271-59-6.18.34"
  ];
  boot.kernelModules = ["wl"];
  boot.extraModulePackages = [config.boot.kernelPackages.broadcom_sta];
  boot.blacklistedKernelModules = ["b43" "bcma" "ssb" "brcmsmac"];
  # End Broadcom Wifi Chip

  system.stateVersion = "26.05";
}
