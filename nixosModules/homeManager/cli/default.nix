{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./tools/bash.nix
    ./tools/claude.nix
    ./tools/git.nix
    ./tools/khal.nix
    ./tools/marp.nix
    ./tools/media.nix
    ./tools/neovim.nix
    ./tools/rclone.nix
    ./tools/tmux.nix
    ./tools/toolchain.nix
    ./tools/utils.nix
    ./tools/yazi.nix

    ./environment/file-normalizer.nix
    ./environment/gemini-api-key.nix
    ./environment/system-maintenance.nix
  ];
}
