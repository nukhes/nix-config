{
  pkgs,
  ...
}:
{
  programs.dconf.enable = true;
  environment.pathsToLink = [ "/share/icons" ];
  environment.systemPackages = with pkgs; [
    gparted
    pavucontrol
    libappindicator
    gnome-themes-extra
  ];

  programs.thunar.enable = true;
  programs.thunar.plugins = with pkgs; [
    thunar-archive-plugin
    thunar-volman
  ];
}
