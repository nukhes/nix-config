{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    fzf
    eza
    zoxide
    tectonic
    bat
    btop
    ripgrep
    dust

    wget
    nil
    nixfmt
    fastfetch
  ];
  
  programs.bash.shellAliases = {
    ls = "eza --icons --color=always --group-directories-first";
    ll = "eza -la --icons --octal-permissions --group-directories-first";
    lt = "eza --tree --level=2";
    cat = "bat --plain";
  };
}
