{ pkgs, lib, ... }:

let
  marp-academic-theme = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/kaisugi/marp-theme-academic/ff135bc225324155f74a256a0ea9df679c00694f/themes/academic.css";
    sha256 = "0dfzw769mrlni81ww9v5paszrygnpjk0ck00c700nxlz0p5vcpl7";
  };

  marpPdfFunction = ''
    marp-pdf() {
      if [ -z "$1" ]; then
        echo "Error: You should pass the path for a Markdown file"
        echo "Usage: marp-pdf <PATH>"
        return 1
      fi
      ${pkgs.marp-cli}/bin/marp --theme ${marp-academic-theme} "$1" --pdf
    }
  '';
in
{
  home.packages = with pkgs; [
    marp-cli
  ];

  programs.bash = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    initExtra = marpPdfFunction;
  };

  programs.zsh = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    initExtra = marpPdfFunction;
  };
}