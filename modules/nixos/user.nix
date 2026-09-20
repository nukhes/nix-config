{ config, inputs, ... }:

{
  nixos.modules.common = { ... }: {
    users = {
      users.user = {
        isNormalUser = true;
        group = "user";
        extraGroups = [
          "networkmanager"
          "wheel"
          "video"
          "audio"
          "docker"
        ];
      };
      groups.user = { };
    };

    age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup-" + builtins.substring 0 8 inputs.self.lastModifiedDate;
      users.user = {
        imports = [
          inputs.agenix.homeManagerModules.default
          config.hm.modules.common
        ];
      };
    };
  };
}
