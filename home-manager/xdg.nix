{ config, pkgs, ... }:

{
  xdg.userDirs = {
    enable = true;
    createDirectories = false;
    download = "${config.home.homeDirectory}/dl";
    desktop = "${config.home.homeDirectory}";
    documents = "${config.home.homeDirectory}";
    music = "${config.home.homeDirectory}";
    pictures = "${config.home.homeDirectory}";
    publicShare = "${config.home.homeDirectory}";
    templates = "${config.home.homeDirectory}";
    videos = "${config.home.homeDirectory}";
    
    extraConfig = {
      XDG_DEVELOPMENT_DIR = "${config.home.homeDirectory}/src";
    };
  };

  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      "application/pdf" = [ "zathura.desktop" ];
      "application/epub+zip" = [ "zathura.desktop" ];
      "application/x-cbz" = [ "zathura.desktop" ];
      "application/postscript" = [ "zathura.desktop" ];

      "text/plain" = [ "nvim.desktop" ];
      "text/markdown" = [ "nvim.desktop" ];
      "text/x-cmake" = [ "nvim.desktop" ];
      "application/json" = [ "nvim.desktop" ];
      "application/javascript" = [ "nvim.desktop" ];
      "application/xml" = [ "nvim.desktop" ];

      "image/png" = [ "sxiv.desktop" ];
      "image/jpeg" = [ "sxiv.desktop" ];
      "image/gif" = [ "sxiv.desktop" ];
      "image/webp" = [ "sxiv.desktop" ];
      "image/bmp" = [ "sxiv.desktop" ];

      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "x-scheme-handler/about" = [ "firefox.desktop" ];
      "x-scheme-handler/unknown" = [ "firefox.desktop" ];
    };

    associations.added = {
      "text/html" = [ "nvim.desktop" ];
    };
  };
}
