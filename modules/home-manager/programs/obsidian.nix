{ config, pkgs, ... }: {
  programs.obsidian.enable = true;

  # In Linux hosts we clone obsidian vault
  home.activation = lib.mkIf (pkgs != null && pkgs.stdenv.isLinux) {
    cloneObsidianVault = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      TARGET_DIR="$HOME/.local/share/obsidian-vault"
      REPO_URL="git@github.com:nukhes/notes.git"
      if [ ! -d "$TARGET_DIR" ]; then
        export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -o StrictHostKeyChecking=accept-new"
        ${pkgs.git}/bin/git clone "$REPO_URL" "$TARGET_DIR"
      fi
    '';
  };
}
