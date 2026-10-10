_:

{
  hm.modules.common =
    { lib, pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      home.packages = with pkgs; [
        electrum
        veracrypt
      ];
    };
}
