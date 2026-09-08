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

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/08b7b247-64fa-4cb8-8413-08d584ac25f6";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/58DD-F000";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  fileSystems."/home/user/.cache" =
    { device = "/dev/disk/by-uuid/922ab3c3-8a3b-4b18-9e47-8d7e5c0b54a7";
      fsType = "ext4";
      options = [ "nofail" ];
    };

  fileSystems."/mnt/games" =
    { device = "/dev/disk/by-uuid/850f918f-0e1e-4a21-b0a3-da64a2728943";
      fsType = "ext4";
      options = [ "nofail" ];
    };

  systemd.tmpfiles.rules = [
    "d /home/user/.cache 0700 user users - -"
  ];

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
