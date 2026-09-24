{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "uhci_hcd"     # USB 1.1 (X200 has UHCI)
        "ehci_pci"     # USB 2.0
        "ahci"         # SATA
        "usb_storage"
        "sd_mod"       # SD card reader
        "sdhci_pci"    # SD host controller
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };

  # TODO: Update these UUIDs after installing NixOS on the X200.
  # Run `nixos-generate-config` on the machine and copy the UUIDs here.
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/CHANGEME-ROOT-UUID";
      fsType = "ext4";
      options = [
        "noatime"      # Skip access-time updates — big perf win on old SSDs/HDDs
        "commit=60"    # Flush journal every 60s instead of 5s
      ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/CHANGEME-BOOT-UUID";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
