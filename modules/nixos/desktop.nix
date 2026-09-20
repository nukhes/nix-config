_:

{
  nixos.modules.common = { pkgs, ... }: {
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
        usbutils
        distrobox
        gparted
        pavucontrol
        libappindicator
        hicolor-icon-theme
        gnome-themes-extra
        polkit_gnome
        quickemu
        quickgui
      ];
    };

    virtualisation.virtualbox.host.enable = true;
  };
}
