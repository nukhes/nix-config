{ config, inputs, ... }:

{
  nixos.modules.common = _: {
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
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFow+cxbnFZR24093m8AhvL3ZZks5Wnzvm1/ftbq64aM nukhes@protonmail.com"
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

    # Evita que o dconf/GIO durante a ativação do Home Manager no boot
    # (antes do login, sem XDG_RUNTIME_DIR) ative o gvfsd-fuse e deixe um
    # mount FUSE órfão em ~/.gvfs ("Connection refused" ao abrir o Thunar).
    systemd.services.home-manager-user.environment = {
      GIO_USE_VFS = "local";
      GVFS_DISABLE_FUSE = "1";
    };
  };
}
