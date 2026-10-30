_:

{
  nixos.modules.common = { pkgs, ... }: {
    programs = {
      nix-ld.enable = true;
      dconf.enable = true;
      thunar = {
        enable = true;
        plugins = with pkgs; [
          (thunar-archive-plugin.overrideAttrs (old: {
            postInstall = (old.postInstall or "") + ''
              ln -s ${pkgs.xarchiver}/libexec/thunar-archive-plugin/xarchiver.tap \
                $out/libexec/thunar-archive-plugin/xarchiver.tap
            '';
          }))
          thunar-volman
        ];
      };
    };

    environment = {
      pathsToLink = [ "/share/icons" ];
      systemPackages = with pkgs; [
        xarchiver
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
  };
}
