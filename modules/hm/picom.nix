{
  hm.modules.common =
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
        shadowOpacity = 0.45;
        
        settings = {
          shadow-radius = 24;
          shadow-offset-x = -22;
          shadow-offset-y = -22;

          shadow-exclude = [
            (wt "menu")
            (wt "dropdown_menu")
            (wt "popup_menu")
            (wt "tooltip")
            (wt "dnd")
            (cg "Polybar")
            "_GTK_FRAME_EXTENTS@:c"
          ];

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
        ] true
        // {
          use-damage = false;
        };

        fade = true;
        fadeDelta = 5;
        fadeSteps = [
          0.03
          0.03
        ];
      };
    };
}
