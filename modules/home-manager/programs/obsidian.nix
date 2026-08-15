{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.obsidian.enable = true;

  home.activation.cloneObsidianVault = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    TARGET_DIR="$HOME/.obsidian"
    REPO_URL="git@github.com:nukhes/notes.git"
    if [ ! -d "$TARGET_DIR" ]; then
      export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -o StrictHostKeyChecking=accept-new"
      ${pkgs.git}/bin/git clone "$REPO_URL" "$TARGET_DIR"
    fi
  '';
}
