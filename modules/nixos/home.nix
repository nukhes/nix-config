{
  pkgs,
  lib,
  inputs,
  modules,
  secrets,
  ...
}:

{
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    backupFileExtension = "backup-" + pkgs.lib.substring 0 8 inputs.self.lastModifiedDate;
    users.user = {
      imports = [
        inputs.agenix.homeManagerModules.default
        "${modules}/home-manager/"
      ];
    };
  };
}
