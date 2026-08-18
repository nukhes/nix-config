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
        "xhci_pci"
        "ehci_pci"
        "ahci"
        "nvme"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };

  # TODO: Replace UUIDs after installing NixOS on the x99.
  # Run `blkid` or `lsblk -f` to get the correct UUIDs.
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/CHANGE-ME-ROOT-UUID";
      fsType = "xfs";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/CHANGE-ME-BOOT-UUID";
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
