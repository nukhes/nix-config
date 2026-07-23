{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./bash.nix
    ./claude.nix
    ./git.nix
    ./khal.nix
    ./marp.nix
    ./media.nix
    ./neovim.nix
    ./qalc.nix
    ./rclone.nix
    ./tmux.nix
    ./utils.nix
    ./yazi.nix

    ./file-normalizer.nix
    ./gemini-api-key.nix
    ./system-maintenance.nix
  ];
}
