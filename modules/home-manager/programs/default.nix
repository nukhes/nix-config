{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf pkgs.stdenv.isLinux {
  imports = [
    ./alacritty.nix
    ./anki.nix
    ./gaming.nix
    ./gparted.nix
    ./obsidian.nix
    ./qgis.nix
    ./vscode.nix
    ./web.nix
    ./xournalpp.nix
    ./zathura.nix
    ./zed.nix
    ./zotero.nix
    ./calibre/calibre.nix
  ];
}
