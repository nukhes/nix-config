_:

{
  hm.modules.common =
    {
      pkgs,
      lib,
      config,
      ...
    }:

    let
      home = config.home.homeDirectory;
      gen = mimes: app: lib.genAttrs mimes (_: [ "${app}.desktop" ]);
    in
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
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
          // gen [
            "image/png"
            "image/jpeg"
            "image/gif"
            "image/webp"
            "image/bmp"
          ] "sxiv"
          // gen [
            "text/html"
            "x-scheme-handler/http"
            "x-scheme-handler/https"
            "x-scheme-handler/about"
            "x-scheme-handler/unknown"
          ] "firefox"
          // gen [
            "application/zip"
            "application/x-zip"
            "application/x-zip-compressed"
            "multipart/x-zip"
            "application/x-7z-compressed"
            "application/x-7z-compressed-tar"
            "application/x-rar"
            "application/x-rar-compressed"
            "application/vnd.rar"
            "application/x-tar"
            "application/x-compressed-tar"
            "application/x-gtar"
            "application/x-tarz"
            "application/gzip"
            "application/x-gzip"
            "application/x-bzip"
            "application/x-bzip-compressed-tar"
            "application/x-bzip2"
            "application/x-bzip2-compressed-tar"
            "application/x-bzip3"
            "application/x-bzip3-compressed-tar"
            "application/x-xz"
            "application/x-xz-compressed-tar"
            "application/zstd"
            "application/x-zstd-compressed-tar"
            "application/x-lzma"
            "application/x-lzma-compressed-tar"
            "application/x-lz4"
            "application/x-lz4-compressed-tar"
            "application/x-lzip"
            "application/x-lzip-compressed-tar"
            "application/x-lrzip"
            "application/x-lrzip-compressed-tar"
            "application/x-lzop"
            "application/x-tzo"
            "application/x-rzip"
            "application/x-rzip-compressed-tar"
            "application/x-compress"
            "application/x-archive"
            "application/x-ar"
            "application/x-arj"
            "application/x-lha"
            "application/x-lhz"
            "application/x-cpio"
            "application/x-cpio-compressed"
            "application/x-deb"
            "application/vnd.debian.binary-package"
            "application/x-rpm"
            "application/x-source-rpm"
            "application/vnd.ms-cab-compressed"
            "application/x-cd-image"
            "application/x-iso9660-image"
            "application/x-java-archive"
            "application/java-archive"
            "application/x-jar"
            "application/x-zoo"
            "application/x-zpaq"
            "application/vnd.squashfs"
          ] "xarchiver";
        associations.added."text/html" = [ "nvim.desktop" ];
      };
    };
}
