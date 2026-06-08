{ pkgs, ... }:

{
  home.packages = [ pkgs.xournalpp ];

  xdg.configFile."xournalpp/toolbar.ini".text = ''
    [Saved Toolbars]
    version=1

    [Default]
    Name=Minimal Single Toolbar
    ToolbarsTop1=PEN,SEPARATOR,TOOL_RULER,TOOL_RECOGNIZER,SEPARATOR,SELECT_REGION,SELECT_RECTANGLE,SEPARATOR,COLOR(0x000000),COLOR(0xff0000),COLOR(0x0000ff),COLOR(0x00cc00)
    ToolbarsTop2=
    ToolbarsBottom=
    ToolbarsLeft=
    ToolbarsRight=
  '';
}
