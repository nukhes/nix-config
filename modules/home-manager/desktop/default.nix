{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./cursor.nix
    ./i3.nix
    ./picom.nix
    ./polybar.nix
    ./redshift.nix
    ./rofi.nix
    ./theme.nix
    ./xdg.nix

    ./alacritty.nix
    ./anki.nix
    ./crypto.nix
    ./gaming.nix
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

  options.modules.desktop.enable = lib.mkOption {
    type = lib.types.bool;
    default = !pkgs.stdenv.isDarwin;
    description = "i3wm desktop";
  };
}
