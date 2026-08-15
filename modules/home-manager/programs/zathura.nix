_:

{
  programs.zathura = {
    enable = true;
    options = {
      selection-clipboard = "clipboard";
      statusbar-h-padding = 0;
      statusbar-v-padding = 0;
      page-padding = 2;
      sandbox = "none";
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
