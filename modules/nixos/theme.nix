{ pkgs, ... }:

{
  stylix = {
    enable = true;
    icons = {
      enable = true;
      package = pkgs.papirus-icon-theme;
    };
    targets.xresources.enable = true;
    polarity = "dark";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
    image = .wallpaper/evangelion.jpg;

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.iosevka;
        name = "Iosevka Term Nerd Font";
      };

      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };

      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };

      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };

      sizes = {
        terminal = 13;
        applications = 12;
        desktop = 11;
        popups = 10;
      };
    };

    opacity = {
      terminal = 1.0;
      applications = 1.0;
    };
  };
}
