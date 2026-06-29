{
  config,
  pkgs,
  ...
}:
{
  environment.pathsToLink = [ "/share/icons" ];

  environment.systemPackages = with pkgs; [
    papirus-icon-theme
    hicolor-icon-theme
    lxappearance
  ];

  environment.variables = {
    GTK_THEME = "Adwaita:dark";
    QT_QPA_PLATFORMTHEME = "gtk3";
  };
}
