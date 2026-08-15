{ pkgs, ... }:
{
  programs = {
    dconf.enable = true;
    thunar = {
      enable = true;
      plugins = with pkgs; [
        thunar-archive-plugin
        thunar-volman
      ];
    };
  };

  environment = {
    pathsToLink = [ "/share/icons" ];
    systemPackages = with pkgs; [
      gparted
      pavucontrol
      libappindicator
      gnome-themes-extra
    ];
  };
}
