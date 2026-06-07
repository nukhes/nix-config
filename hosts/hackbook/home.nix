{ config, pkgs, agenixModule, ... }:

{
  home.username = "user";
  home.homeDirectory = "/home/user";
  programs.git.enable = true;
  home.stateVersion = "26.05";

  imports = map (file: ../../home-manager + "/${file}") [
    "i3.nix"
    "vscode.nix"
    "theme.nix"
    "bash.nix"
    "alacritty.nix"
    "redshift.nix"
    "tmux.nix"
    "neovim.nix"
    "yazi.nix"
    "rofi.nix"
    "picom.nix"
    "rclone.nix"
    "zathura.nix"
    "git.nix"
  ];
}
