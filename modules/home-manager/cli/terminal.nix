{
  config,
  pkgs ? null,
  lib,
  ...
}:

let
  inherit (config.home) homeDirectory;
  inherit (lib) mkIf optionals;
  isLinux = pkgs != null && pkgs.stdenv.isLinux;
  isDarwin = pkgs != null && pkgs.stdenv.isDarwin;

  nixAliases = {
    noise = "play -n synth brownnoise mix synth sine amod 0.1";
    rebuild = "sudo nixos-rebuild switch --flake ${homeDirectory}/.nix-config#$(hostname)";
    cleanup = "sudo nix-collect-garbage -d && sudo nix-store --optimise -v";
    upgrade = "cd ${homeDirectory}/.nix-config && nix flake update && sudo nixos-rebuild switch --flake .#$(hostname) && sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +2 && sudo nix-store --gc";
    agenix-add = "nix run github:ryantm/agenix -- --edit";
    agenix-rekey = "nix run github:ryantm/agenix -- --rekey";
    nixfmt-run = "cd ~/.nix-config && nix run nixpkgs#statix -- fix . && nix run nixpkgs#nixfmt-tree -- .";
  };

  gitAliases = {
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
  };

  aliases = {
    ls = "eza --icons --color=always --group-directories-first";
    ll = "eza -la --icons --octal-permissions --group-directories-first";
    lt = "eza --tree --level=2";
    cat = "bat --plain";
    hl = "hledger";
    hln = "hledger balance assets --forecast=thismonth -e tomorrow";
    nv = "vim ~/.nix-config";
  };
in
{
  home.packages =
    with pkgs;
    [
      fzf
      eza
      zoxide
      bat
      ripgrep
      jq
      hledger
      libqalculate
      lazygit
      gh
      xclip
      typst
    ]
    ++ optionals isLinux [
      asdf-vm
      cargo
      gcc
      rustc
      lua
      luarocks
      btop
      tectonic
      dust
      wget
      nil
      nixfmt
      fastfetch
      duckdb
      tailscale
      android-tools
      nmap
      fping
    ];

  programs.bash = mkIf isLinux {
    enable = true;
    shellAliases = aliases // nixAliases // gitAliases;
  };

  programs.zsh = mkIf isDarwin {
    enable = true;
    shellAliases = aliases;
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user.name = "Pedro Henrique";
      user.email = "79018158+nukhes@users.noreply.github.com";
      init.defaultBranch = "main";
      pull.rebase = false;
      rebase.autoStash = true;
    };
  };
}
