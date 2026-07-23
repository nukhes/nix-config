{
  config,
  pkgs,
  ...
}:
{
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.iosevka
      corefonts
      vista-fonts
    ];
    fontconfig = {
      defaultFonts = {
        serif = [ "Iosevka Nerd Font" ];
        sansSerif = [ "Iosevka Nerd Font" ];
        monospace = [ "Iosevka Nerd Font" ];
      };
    };
  };

  environment.pathsToLink = [ "/share/icons" ];

  environment.systemPackages = with pkgs; [
    papirus-icon-theme
    hicolor-icon-theme
    libappindicator
    gnome-themes-extra
  ];

  environment.variables = {
    GTK_THEME = "Adwaita:dark";
    QT_QPA_PLATFORMTHEME = "gtk3";
  };

  programs.thunar.enable = true;
  programs.thunar.plugins = with pkgs; [
    thunar-archive-plugin
    thunar-volman
  ];
}
