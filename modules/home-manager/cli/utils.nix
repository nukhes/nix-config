{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    asdf-vm
    cargo
    gcc
    rustc
    lua
    luarocks

    fzf
    eza
    zoxide
    tectonic
    bat
    btop
    ripgrep
    dust
    jq

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
