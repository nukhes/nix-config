{ config, pkgs, ... }:

{
  home.username = "user";
  home.homeDirectory = "/home/user";
  programs.git.enable = true;
  home.stateVersion = "26.05";
  imports = [
    ../../home-manager/i3.nix
    ../../home-manager/vscode.nix
    ../../home-manager/theme.nix
    ../../home-manager/bash.nix
    ../../home-manager/alacritty.nix
    ../../home-manager/redshift.nix
    ../../home-manager/tmux.nix
    ../../home-manager/neovim.nix
    ../../home-manager/yazi.nix
    ../../home-manager/rofi.nix
    ../../home-manager/picom.nix
    ../../home-manager/rclone.nix
    ../../home-manager/zathura.nix
    ../../home-manager/git.nix
  ];
}
