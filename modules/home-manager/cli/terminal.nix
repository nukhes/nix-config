{
  config,
  pkgs ? null,
  lib,
  ...
}:

let
  nixAliases = {
    noise = "play -n synth brownnoise mix synth sine amod 0.1";
    rebuild = "sudo nixos-rebuild switch --flake ${config.home.homeDirectory}/.nix-config#$(hostname)";
    cleanup = "sudo nix-collect-garbage -d && sudo nix-store --optimise -v";
    upgrade = "cd ${config.home.homeDirectory}/.nix-config && nix flake update && sudo nixos-rebuild switch --flake .#$(hostname) && sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +2 && sudo nix-store --gc";
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
      veracrypt
      electrum
      lazygit
      gh
      xclip
    ]
    ++ lib.optionals (pkgs != null && pkgs.stdenv.isLinux) [
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
    ];

  programs.bash = lib.mkIf (pkgs != null && pkgs.stdenv.isLinux) {
    enable = true;
    shellAliases = aliases // nixAliases // gitAliases;
  };
  programs.zsh = lib.mkIf (pkgs != null && pkgs.stdenv.isDarwin) {
    enable = true;
    shellAliases = aliases;
  };
  programs.tmux = {
    enable = true;
    shortcut = "space";
    keyMode = "vi";
    mouse = true;
    historyLimit = 10000;
    terminal = "tmux-256color";

    extraConfig = ''
      unbind C-b
      set -g prefix M-space
      bind M-space send-prefix

      set -g base-index 1
      setw -g pane-base-index 1
      set -g renumber-windows on

      bind v split-window -h -c "#{pane_current_path}"
      bind h split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %

      bind -n M-h select-pane -L
      bind -n M-j select-pane -D
      bind -n M-k select-pane -u
      bind -n M-l select-pane -R

      bind -r C-Up resize-pane -U 5
      bind -r C-Down resize-pane -D 5
      bind -r C-Left resize-pane -L 5
      bind -r C-Right resize-pane -R 5

      bind r source-file ~/.config/tmux/tmux.conf \; display "Configuração recarregada!"

      set -s escape-time 0

      set -g status-style bg=default,fg="#cdd6f4"
      set -g status-left ""
      set -g status-right "#[fg=#b4befe,bold]#S "
      setw -g window-status-current-format "#[fg=#1e1e2e,bg=#cba6f7,bold] #I:#W "
      setw -g window-status-format "#[fg=#a6adc8,bg=default] #I:#W "
      set -g pane-border-style fg="#313244"
      set -g pane-active-border-style fg=#b4befe
    '';
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
