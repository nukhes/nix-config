{
  config,
  pkgs,
  ...
}: {
  programs.rofi = {
    enable = true;
    font = "Iosevka Nerd Font 11";

    extraConfig = {
      modi = "drun,run,window";
      show-icons = true;
      drun-display-format = "{name}";
      sidebar-mode = false;
    };

    theme = let
      inherit (config.lib.formats.rasi) mkLiteral;
    in {
      "*" = {
        bg-col = mkLiteral "#1e1e2e";
        bg-col-light = mkLiteral "#1e1e2e";
        border-col = mkLiteral "#cba6f7";
        selected-col = mkLiteral "#313244";
        text-col = mkLiteral "#cdd6f4";
        text-col-selected = mkLiteral "#cba6f7";
        text-col-dim = mkLiteral "#6c7086";

        width = 600;
        background-color = mkLiteral "@bg-col";
      };

      "window" = {
        background-color = mkLiteral "@bg-col";
        border = 1;
        border-radius = mkLiteral "10px";
        border-color = mkLiteral "@border-col";
        padding = mkLiteral "10px";
      };

      "mainbox" = {
        background-color = mkLiteral "@bg-col";
        children = map mkLiteral ["inputbar" "listview"];
      };

      "inputbar" = {
        children = map mkLiteral ["prompt" "entry"];
        background-color = mkLiteral "@bg-col";
        padding = 2;
      };

      "prompt" = {
        background-color = mkLiteral "@bg-col";
        text-color = mkLiteral "@text-col-selected";
        font = "Iosevka Nerd Font Bold 11";
        padding = mkLiteral "0px 10px 0px 0px";
      };

      "entry" = {
        background-color = mkLiteral "@bg-col";
        text-color = mkLiteral "@text-col";
        placeholder = "Search...";
        placeholder-color = mkLiteral "@text-col-dim";
      };

      "listview" = {
        border = mkLiteral "0px 0px 0px";
        padding = mkLiteral "6px 0px 0px";
        margin = mkLiteral "10px 0px 0px 0px";
        columns = 1;
        lines = 8;
        background-color = mkLiteral "@bg-col";
      };

      "element" = {
        padding = 5;
        background-color = mkLiteral "@bg-col";
        text-color = mkLiteral "@text-col";
      };

      "element selected" = {
        background-color = mkLiteral "@selected-col";
        text-color = mkLiteral "@text-col-selected";
      };

      "element-text" = {
        background-color = mkLiteral "transparent";
        text-color = mkLiteral "inherit";
      };
    };
  };
}
