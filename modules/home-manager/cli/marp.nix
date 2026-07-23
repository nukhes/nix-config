{
  pkgs,
  ...
}:
let
  marp-academic-theme = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/kaisugi/marp-theme-academic/ff135bc225324155f74a256a0ea9df679c00694f/themes/academic.css";
    sha256 = "0dfzw769mrlni81ww9v5paszrygnpjk0ck00c700nxlz0p5vcpl7";
  };
in
{
  home.packages = with pkgs; [
    marp-cli
  ];

  programs.bash = {
    enable = true;
    initExtra = ''
      marp-pdf() {
        if [ -z "$1" ]; then
          echo "Error: You should pass the path for a Markdown file"
          echo "Usage: marp-pdf <PATH>"
          return 1
        fi
        marp --theme /nix/store/z8ja1mingii3mrk4ncjmabc2cvhnscwk-academic.css "$1" --pdf
      }
    '';
  };
}
