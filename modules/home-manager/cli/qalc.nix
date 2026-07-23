{ pkgs, ... }:

{
  home.packages = with pkgs; [
    libqalculate
  ];

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
