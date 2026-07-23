{
  config,
  pkgs,
  ...
}:
{
  xdg.portal = {
    enable = true;
    config.common.default = "gtk";
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  services.flatpak = {
    enable = true;

    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];

    packages = [
      "com.usebottles.bottles"
      "org.ppsspp.PPSSPP"
    ];

    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };

    overrides = {
      "com.usebottles.bottles" = {
        Context = {
          filesystems = [
            "xdg-data/applications:create"
            "~/.local/share/games"
            "xdg-run/dri:ro"
            "~/.config:ro"
          ];
        };
      };
    };
  };
}
