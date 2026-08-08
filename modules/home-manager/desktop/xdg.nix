{ lib, config, ... }:
let
  home = config.home.homeDirectory;
  gen = mimes: app: lib.genAttrs mimes (_: [ "${app}.desktop" ]);
in
{
  xdg.userDirs = {
    enable = true;
    download = home;
    desktop = home;
    documents = home;
    music = home;
    pictures = home;
    publicShare = home;
    templates = home;
    videos = home;
    extraConfig.XDG_DEVELOPMENT_DIR = "${home}/src";
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications =
      gen [ "inode/directory" ] "yazi"
      // gen [
        "application/pdf"
        "application/epub+zip"
        "application/x-cbz"
        "application/postscript"
      ] "org.pwmt.zathura"
      // gen [
        "text/plain"
        "text/markdown"
        "text/x-cmake"
        "application/json"
        "application/javascript"
        "application/xml"
      ] "nvim"
      // gen [ "image/png" "image/jpeg" "image/gif" "image/webp" "image/bmp" ] "sxiv"
      // gen [
        "text/html"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/about"
        "x-scheme-handler/unknown"
      ] "firefox";
    associations.added."text/html" = [ "nvim.desktop" ];
  };
}
