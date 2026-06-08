{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    wget
    fzf
    dust
    eza
    zoxide
    rclone
    rsync
    lazygit
    gh
    tectonic
    bat
    asdf-vm
    cargo
    gcc
    rustc
    lua
    luarocks
    nil
    nixfmt
    fastfetch
    mpv
    ani-cli
  ];
}

