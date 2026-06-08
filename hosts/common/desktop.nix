{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    xarchiver
    papirus-icon-theme
    calibre
    xournalpp
    gparted
    anki-bin
    brightnessctl
    maim
    xclip
    picom
    sxiv
    ouch
  ];

  environment.variables = {
    GTK_THEME = "Adwaita:dark";
    QT_QPA_PLATFORMTHEME = "gtk3";
  };

  services.xserver.xkb = {
    layout = "us";
    variant = "intl";
  };

  services.xserver = {
    enable = true;
    autoRepeatDelay = 200;
    autoRepeatInterval = 35;
    windowManager.i3.enable = true;
  };

  services.displayManager.ly.enable = true;
  services.udisks2.enable = true;

  security.polkit.enable = true;
  security.rtkit.enable = true;

  programs.dconf.enable = true;
  programs.firefox.enable = true;

  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-vcs-plugin
    ];
  };

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.iosevka
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
