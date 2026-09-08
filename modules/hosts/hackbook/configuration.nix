{
  pkgs,
  modules,
  secrets,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./broadcom.nix
    "${modules}/nixos"
    "${modules}/nixos/laptop.nix"
  ];

  networking = {
    hostName = "hackbook";
    networkmanager = {
      enable = true;
      wifi.powersave = false;
    };
  };

  age.secrets.eduroam = {
    file = "${secrets}/eduroam.age";
    path = "/etc/NetworkManager/system-connections/eduroam.nmconnection";
    mode = "0600";
    owner = "root";
    group = "root";
    symlink = false;
  };

  environment.systemPackages = [ pkgs.moonlight-qt ];

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
