{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    # i3wm
    ./cursor.nix
    ./i3.nix
    ./picom.nix
    ./polybar.nix
    ./redshift.nix
    ./rofi.nix
    ./theme.nix
    ./xdg.nix

    # Desktop Apps
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

    # CLI Tools
    ./antigravity.nix
    ./claude.nix
    ./git.nix
    ./hledger.nix
    ./khal.nix
    ./marp.nix
    ./media.nix
    ./neovim.nix
    ./qalc.nix
    ./rclone.nix
    ./shell.nix
    ./tmux.nix
    ./utils.nix
    ./yazi.nix
  ];

  options.modules.desktop.enable = lib.mkOption {
    type = lib.types.bool;
    default = !pkgs.stdenv.isDarwin;
    description = "i3wm desktop";
  };

  config = {
    home.username = "user";
    home.stateVersion = "26.05";
    home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/user" else "/home/user";
  };
}
