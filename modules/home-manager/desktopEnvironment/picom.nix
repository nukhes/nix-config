_: {
  services.picom = {
    enable = true;
    backend = "glx";
    vSync = true;
    shadow = true;
    shadowOpacity = 0.4;
    shadowOffsets = [
      (-15)
      (-15)
    ];
    shadowExclude = [
      "window_type = 'menu'"
      "window_type = 'dropdown_menu'"
      "window_type = 'popup_menu'"
      "window_type = 'tooltip'"
      "window_type = 'dnd'"
      "class_g = 'i3-frame'"
      "_GTK_FRAME_EXTENTS@:c"
    ];

    fade = true;
    fadeDelta = 5;
    fadeSteps = [
      0.03
      0.03
    ];
    fadeExclude = [ ];

    settings = {
      corner-radius = 12;
      rounded-corners-exclude = [
        "window_type = 'dock'"
        "window_type = 'desktop'"
        "class_g = 'i3bar'"
        "class_g = 'dmenu'"
      ];

      blur = {
        method = "dual_kawase";
        strength = 4;
        background = false;
        background-frame = false;
        background-fixed = false;
      };

      blur-background-exclude = [
        "window_type = 'dock'"
        "window_type = 'desktop'"
        "window_type = 'tooltip'"
        "class_g = 'slop'"
        "class_g = 'maim'"
        "_GTK_FRAME_EXTENTS@:c"
      ];

      detect-client-opacity = true;
      detect-transient = true;
      detect-client-leader = true;
      mark-wmwin-focused = true;
      mark-ovredir-focused = true;
      use-damage = true;
    };
  };
}
