{
  {
    config,
    lib,
    pkgs ? null,
    ...
  }:
let
  baseImports = [
    ./claude.nix
    ./git.nix
    ./yazi.nix
  ];

  pkgsImports = [
    ./khal.nix
    ./marp.nix
    ./media.nix
    ./neovim.nix
    ./shell.nix
    ./tmux.nix
    ./utils.nix
  ];
in
{
