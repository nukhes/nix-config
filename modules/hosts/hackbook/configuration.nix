{
  pkgs,
  modules,
  secrets,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    "${modules}/nixos/common/"
    "${modules}/nixos/laptop.nix"
    "${modules}/nixos/broadcom.nix"
  ];

  networking = {
    hostName = "hackbook";
    networkmanager = {
      enable = true;
      wifi.powersave = false;
    };
  };

  environment.systemPackages = [ pkgs.moonlight-qt ];
  kernelPackages = pkgs.linuxPackages_;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General = {
      Experimental = true;
      FastConnectable = true;
    };
  };
  services.blueman.enable = true;

  nix.settings = {
    max-jobs = 1;
    cores = 1;
  };

  system.stateVersion = "26.05";
}
