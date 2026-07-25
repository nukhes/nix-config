{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./claude.nix
    ./git.nix
    ./khal.nix
    ./marp.nix
    ./media.nix
    ./neovim.nix
    ./shell.nix
    ./tmux.nix
    ./utils.nix
    ./yazi.nix

  ] ++ lib.optionals pkgs.stdenv.isLinux [
    ./gemini-api-key.nix
    ./rclone.nix
  ];
}
