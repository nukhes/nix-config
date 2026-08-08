{ lib, ... }:
let
  wt = t: "window_type = '${t}'";
  cg = c: "class_g = '${c}'";
  boolAttrs = names: val: lib.genAttrs names (_: val);
in
{
  services.picom = {
    enable = true;
    backend = "glx";
    vSync = true;
    shadow = true;
    shadowOpacity = 0.4;
    shadowExclude = [
      (wt "menu")
      (wt "dropdown_menu")
      (wt "popup_menu")
      (wt "tooltip")
      (wt "dnd")
      (cg "i3-frame")
      "_GTK_FRAME_EXTENTS@:c"
    ];

    fade = true;
    fadeDelta = 5;
    fadeSteps = [
      0.03
      0.03
    ];

    settings = {
      corner-radius = 12;
      rounded-corners-exclude = [
        (wt "dock")
        (wt "desktop")
        (cg "i3bar")
        (cg "dmenu")
      ];

      blur = {
        method = "dual_kawase";
        strength = 4;
      }
      // boolAttrs [ "background" "background-frame" "background-fixed" ] false;

      blur-background-exclude = [
        (wt "dock")
        (wt "desktop")
        (wt "tooltip")
        (cg "slop")
        (cg "maim")
        "_GTK_FRAME_EXTENTS@:c"
      ];
    }
    // boolAttrs [
      "detect-client-opacity"
      "detect-transient"
      "detect-client-leader"
      "mark-wmwin-focused"
      "mark-ovredir-focused"
      "use-damage"
    ] true;
  };
}
