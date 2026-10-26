{ inputs, ... }:

{
  hm.modules.common =
    { lib, pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      home.packages = [
        inputs.scidavis-nix.packages.${pkgs.stdenv.hostPlatform.system}.scidavis
      ];
    };
}
