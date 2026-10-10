_:

{
  hm.modules.gaming =
    { lib, pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      home.packages = with pkgs; [
        umu-launcher
        protonup-qt
        protontricks
        winetricks
      ];
    };
}
