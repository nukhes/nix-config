{
  config,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [ papirus-icon-theme ];

  environment.variables = {
    GTK_THEME = "Adwaita:dark";
    QT_QPA_PLATFORMTHEME = "gtk3";
  };
}
