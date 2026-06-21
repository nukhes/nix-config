{
  config,
  pkgs,
  ...
}: {
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.iosevka
      corefonts
      vista-fonts
    ];
    fontconfig = {
      defaultFonts = {
        serif = ["Iosevka Nerd Font"];
        sansSerif = ["Iosevka Nerd Font"];
        monospace = ["Iosevka Nerd Font"];
      };
    };
  };
}
