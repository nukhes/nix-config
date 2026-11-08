_:

{
  hm.modules.common = _: {
    programs.zathura = {
      enable = true;
      options = {
        selection-clipboard = "clipboard";
        statusbar-h-padding = 0;
        statusbar-v-padding = 0;
        page-v-padding = 2;
        page-h-padding = 2;
        database = "sqlite";
        continuous-hist-save = true;
      };
      mappings = {
        "<C-l>" = "feedkeys \":blist \"";
        "<C-j>" = "feedkeys \":bjump \"";
        "<C-m>" = "feedkeys \":bmark \"";
      };
    };
  };
}
