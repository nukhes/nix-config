_:

{
  hm.modules.common =
    { lib, pkgs, ... }:
    lib.mkIf pkgs.stdenv.isLinux {
      home.packages = with pkgs; [
        electrum
        veracrypt
      ];
    };
}
