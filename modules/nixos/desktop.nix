{ pkgs, ... }:
{
  programs = {
    nix-ld.enable = true;
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
      distrobox
      gparted
      pavucontrol
      libappindicator
      gnome-themes-extra

      # essential tools to manage idevices
      idevicerestore
      libimobiledevice
      usbutils
      usbmuxd
    ];
  };
}
