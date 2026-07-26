{ pkgs, ... }:
lib.mkIf pkgs.stdenv.isLinux {
  home.packages = with pkgs; [
    umu-launcher
    protonup-qt
    protontricks
    winetricks
  ];

  programs.prismlauncher.enable = true;

  programs.java = {
    enable = true;
    package = pkgs.openjdk17;
  };
}
