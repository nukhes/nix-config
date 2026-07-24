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

    libqalculate
    gperiodic
  ];

  programs.bash.shellAliases = {
    ls = "eza --icons --color=always --group-directories-first";
    ll = "eza -la --icons --octal-permissions --group-directories-first";
    lt = "eza --tree --level=2";
    cat = "bat --plain";
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
