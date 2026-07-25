{ pkgs, lib, ... }:

let
  sharedAliases = {
    ls = "eza --icons --color=always --group-directories-first";
    ll = "eza -la --icons --octal-permissions --group-directories-first";
    lt = "eza --tree --level=2";
    cat = "bat --plain";
  };
in
{
  home.packages = with pkgs; [
    fzf
    eza
    zoxide
    bat
    ripgrep
    jq

  ] ++ lib.optionals pkgs.stdenv.isLinux [
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
    libqalculate
  ];

  programs.bash = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    shellAliases = sharedAliases;
  };

  programs.zsh = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    shellAliases = sharedAliases;
  };

  home.file.".config/qalculate/qalculate.cfg" = {
    text = ''
      [General]
      colorize=1
      decimals=6
      decimal_comma=1
      fraction_mode=1
      auto_completion=1
      save_history=1
    '';
    force = true;
  };
}