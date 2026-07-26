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

  home.file.".config/pupgui/config.ini" = {
    text = ''
      [pupgui2]
      theme = system

      [pupgui]
      installdir = /home/user/.local/share/Steam/compatibilitytools.d/
    '';
    force = true;
  };
}
