_: {
  programs.zathura = {
    enable = true;
    options = {
      selection-clipboard = "clipboard";
      statusbar-h-padding = 0;
      statusbar-v-padding = 0;
      page-padding = 2;
      sandbox = "none";
      default-bg = "#04040a";
      default-fg = "#ffffff";
      statusbar-bg = "#07070a";
      statusbar-fg = "#c0caf5";
      inputbar-bg = "#07070a";
      inputbar-fg = "#bb9af7";
      highlight-color = "#e0af68";
      highlight-active-color = "#9ece6a";
      recolor = false;
      recolor-darkcolor = "#ffffff";
      recolor-lightcolor = "#07070a";
      recolor-keephue = true;
      database = "sqlite";
      history-autosave = true;
    };
    mappings = {
      "<C-l>" = "feedkeys \":blist \"";
      "<C-j>" = "feedkeys \":bjump \"";
      "<C-m>" = "feedkeys \":bmark \"";
    };
  };
}
