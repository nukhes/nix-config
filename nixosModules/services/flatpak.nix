{
  config,
  pkgs,
  ...
}:
{
    xdg.portal.enable = true;
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

    services.flatpak = {
        enable = true;

        remotes = [{
            name = "flathub";
            location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
        }];

        packages = [
            "com.usebottles.bottles"
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
