_:
let
  fontName = "Iosevka Nerd Font";
  colors =
    let
      c = {
        base = "#04040a";
        text = "#ffffff";
        overlay0 = "#7f849c";
        rosewater = "#f5e0dc";
        lavender = "#b4befe";
        green = "#a6e3a1";
        yellow = "#f9e2af";
        pink = "#f5c2e7";
        surface1 = "#1e1e2e";
        surface2 = "#252730";
        red = "#f38ba8";
        blue = "#89b4fa";
        cyan = "#94e2d5";
        subtext0 = "#a6adc8";
        subtext1 = "#bac2de";
      };
      fgBase = {
        foreground = c.base;
      };
      bgSub0 = {
        background = c.subtext0;
      };
      normal = {
        black = c.surface1;
        inherit (c) red;
        inherit (c) green;
        inherit (c) yellow;
        inherit (c) blue;
        magenta = c.pink;
        inherit (c) cyan;
        white = c.subtext1;
      };
    in
    {
      primary = {
        background = c.base;
        foreground = c.text;
        dim_foreground = c.overlay0;
      };
      cursor = {
        text = c.base;
        cursor = c.rosewater;
      };
      vi_mode_cursor = {
        text = c.base;
        cursor = c.lavender;
      };
      search = {
        matches = fgBase // bgSub0;
        focused_match = fgBase // {
          background = c.green;
        };
      };
      hints = {
        start = fgBase // {
          background = c.yellow;
        };
        end = fgBase // bgSub0;
      };
      line_indicator = fgBase // bgSub0;
      selection = {
        text = c.base;
        background = c.pink;
      };
      inherit normal;
      bright = normal // {
        black = c.surface2;
        white = c.subtext0;
      };
      dim = normal;
    };
in
{
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding = {
          x = 0;
          y = 0;
        };
        dynamic_title = true;
      };
      font = {
        size = 11.0;
      }
      //
        builtins.mapAttrs
          (_: style: {
            family = fontName;
            inherit style;
          })
          {
            normal = "Regular";
            bold = "Bold";
            italic = "Italic";
            bold_italic = "Bold Italic";
          };
      inherit colors;
    };
  };
}
