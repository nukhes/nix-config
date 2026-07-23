{
  config,
  lib,
  pkgs,
  ...
}:
{
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
    ./zotero.nix
    
    ./calibre/calibre.nix
  ];
}
