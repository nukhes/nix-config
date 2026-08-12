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
    ./broadcom.nix

    "${modules}/nixos"
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.user = {
      imports = [
        inputs.agenix.homeManagerModules.default
        "${modules}/home-manager/"
      ];
    };
    backupFileExtension = "backup";
  };

  # ==========================================
  # AJUSTES DE LIMITES DO SISTEMA (FILE LEAKS)
  # ==========================================
  boot.kernel.sysctl = {
    "fs.file-max" = 2097152;
    "fs.inotify.max_user_watches" = 524288;
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
