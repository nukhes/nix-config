{ config, lib, pkgs, ... }:
lib.mkIf pkgs.stdenv.isLinux {
  home.packages = [ pkgs.xournalpp ];
  xdg.configFile."xournalpp/toolbar.ini".text = ''
    [Default]
    toolbarTop1=PEN,PLAIN,DOTTED,SELECT_RECTANGLE,COMPASS,SETSQUARE,SEPARATOR,TEXT,MATH_TEX,DRAW_ARROW,RULER,DRAW_COORDINATE_SYSTEM,DRAW_RECTANGLE,DRAW_ELLIPSE,TOOL_FILL,SEPARATOR,COLOR(10),COLOR(0),COLOR(6),COLOR(3),COLOR(2),COLOR(7)
    name=custom
  '';
}
