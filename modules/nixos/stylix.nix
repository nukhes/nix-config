_:

{
  nixos.modules.common = { pkgs, ... }: {
    stylix = {
      enable = true;
      polarity = "dark";
      base16Scheme = ./ayu-dark.yaml;
      image = pkgs.runCommand "solid-wallpaper.png" {
        nativeBuildInputs = [ pkgs.imagemagick ];
      } "convert -size 3840x2160 xc:'#070707' $out";

      icons = {
        enable = true;
        package = pkgs.papirus-icon-theme;
        dark = "Papirus-Dark";
        light = "Papirus-Light";
      };

      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.iosevka;
          name = "Iosevka Nerd Font Mono";
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
          terminal = 10;
          applications = 10;
          desktop = 10;
          popups = 10;
        };
      };

      opacity = {
        terminal = 1.0;
        applications = 1.0;
      };
    };
  };
}
