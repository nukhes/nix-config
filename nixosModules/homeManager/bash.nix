{
  config,
  pkgs,
  ...
}:
{
  programs.bash = {
    enable = true;
    shellAliases = {
      # System Maintenance
      rebuild = "sudo nixos-rebuild switch --flake ${config.home.homeDirectory}/.nix-config#$(hostname)";
      upgrade = "cd ${config.home.homeDirectory}/.nix-config && nix flake update && sudo nixos-rebuild switch --flake .#$(hostname) && sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +2 && sudo nix-store --gc";
      agenix-add = "nix run github:ryantm/agenix -- --edit";
      agenix-rekey = "nix run github:ryantm/agenix -- --rekey";
      nixfmt-run = "cd ~/.nix-config && nix run nixpkgs#statix -- fix . && nix run nixpkgs#nixfmt-tree -- .";
      # End System Maintenance

      # Rust modern replaces
      ls = "eza --icons --color=always --group-directories-first";
      ll = "eza -la --icons --octal-permissions --group-directories-first";
      lt = "eza --tree --level=2";
      cat = "bat --plain";
      # End Rust modern replaces

      # Git
      git = "git";
      gs = "git status";
      gss = "git status -s";
      ga = "git add";
      gaa = "git add --all";
      gc = "git commit";
      gcm = "git commit -m";
      gca = "git commit --amend";
      gp = "git push";
      gpl = "git pull";
      gpo = "git push origin HEAD";
      gl = "git log --oneline --graph --decorate --all";
      gd = "git diff";
      gds = "git diff --staged";
      gb = "git branch";
      gba = "git branch -a";
      gco = "git checkout";
      gcb = "git checkout -b";
      gcp = "git cherry-pick";
      gr = "git restore";
      # End Git

      # Misc
      noise = "play -n synth brownnoise mix synth sine amod 0.1";
      # End Misc
    };
  };
}
