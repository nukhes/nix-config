{ config, lib, pkgs, ... }:

{
  programs.zathura = {
    enable = true;
    options = {
      selection-clipboard = "clipboard";
      statusbar-h-padding = 0;
      statusbar-v-padding = 0;
      page-padding = 1;
      sandbox = "none";

      default-bg = "#1a1b26";
      default-fg = "#c0caf5";
      statusbar-bg = "#24283b";
      statusbar-fg = "#c0caf5";
      inputbar-bg = "#1a1b26";
      inputbar-fg = "#bb9af7";

      highlight-color = "#e0af68";
      highlight-active-color = "#9ece6a";

      recolor = false;
      recolor-darkcolor = "#c0caf5";
      recolor-lightcolor = "#1a1b26";
      recolor-keephue = true;

      database = "sqlite";
      history-autosave = true;
    };
  };
}
