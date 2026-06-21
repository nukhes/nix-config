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

  services.xserver.xkb = {
    layout = "us";
    variant = "intl";
  };

  services.xserver = {
    enable = true;
    autoRepeatDelay = 200;
    autoRepeatInterval = 35;
    windowManager.i3.enable = true;
  };
}
