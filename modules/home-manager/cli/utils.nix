{ pkgs ? null, lib, ... }:

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

  ] ++ lib.optionals (pkgs != null && pkgs.stdenv.isLinux) [
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
  ];

  programs.bash = lib.mkIf (pkgs != null && pkgs.stdenv.isLinux) {
    enable = true;
    shellAliases = sharedAliases;
  };

  programs.zsh = lib.mkIf (pkgs != null && pkgs.stdenv.isDarwin) {
    enable = true;
    shellAliases = sharedAliases;
  };
}