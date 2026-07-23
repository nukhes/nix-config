{ pkgs, ... }: {
  home.packages = with pkgs; [
    prismlauncher
    
    umu-launcher
    protonup-qt
    protontricks
    winetricks
  ];

  programs.java = {
    enable = true;
    package = pkgs.openjdk17;
  };
}
