{
  config,
  ...
}:
{
  programs.rofi = {
    enable = true;

    extraConfig = {
      modi = "drun,run,window";
      show-icons = true;
      drun-display-format = "{name}";
      sidebar-mode = false;
    };
  };
}
