{ pkgs, ... }: {
  home.packages = with pkgs; [
    prismlauncher
  ];

  programs.java = {
    enable = true;
    package = pkgs.openjdk17;
  };
}
