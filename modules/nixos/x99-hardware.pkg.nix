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

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/08b7b247-64fa-4cb8-8413-08d584ac25f6";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/58DD-F000";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  fileSystems."/mnt/kootion512" = {
    device = "/dev/disk/by-uuid/c4095e1b-f404-4007-bdf6-90b739f09d8e";
    fsType = "ext4";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/toshiba300" = {
    device = "/dev/disk/by-uuid/850f918f-0e1e-4a21-b0a3-da64a2728943";
    fsType = "ext4";
    options = [ "nofail" ];
  };

  systemd.tmpfiles.rules = [
    "d '/mnt/kootion512' 0700 user users - -"
    "d '/mnt/toshiba300' 0700 user users - -"
  ];

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
