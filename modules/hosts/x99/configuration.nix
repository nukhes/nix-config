{
  config,
  pkgs,
  lib,
  inputs,
  modules,
  secrets,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./nvidia.nix
    "${modules}/nixos"
  ];

  networking = {
    hostName = "x99";
    networkmanager.enable = true;
  };

  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    backupFileExtension = "backup";
    users.user = {
      imports = [
        inputs.agenix.homeManagerModules.default
        "${modules}/home-manager/"
      ];
    };
  };

  powerManagement.cpuFreqGovernor = "performance";

  boot.kernel.sysctl = {
    "fs.file-max" = 2097152;
    "fs.inotify.max_user_watches" = 524288;
    "vm.swappiness" = 10;
  };

  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "524288";
    }
    {
      domain = "*";
      type = "hard";
      item = "nofile";
      value = "1048576";
    }
  ];

  system.stateVersion = "26.05";
}
