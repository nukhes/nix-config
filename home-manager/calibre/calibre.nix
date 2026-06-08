{ pkgs, ... }:

{
  programs.calibre.enable = true;

  xdg.configFile."calibre/gui.json".text = builtins.readFile ./gui.json;
  xdg.configFile."calibre/gui.py.json".text = builtins.readFile ./gui.py.json;
  xdg.configFile."calibre/global.py.json".text = builtins.readFile ./global.py.json;
}
