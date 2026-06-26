{
  config,
  pkgs,
  ...
}:
{
    xdg.portal.enable = true;
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    services.flatpak.enable = true;
    services.flatpak.overrides = {
        "com.usebottles.bottles" = {
            filesystems = [
                "~/.local/share/games"
                "xdg-run/dri:ro" 
            ];
            environment = {
                "XDG_DATA_DIRS" = "/run/current-system/sw/share:/share";
            };
        };
    };
}
