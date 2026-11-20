{
  hm.modules.common =
    {
      config,
      lib,
      osConfig ? null,
      ...
    }:

    let
      wt = t: "window_type = '${t}'";
      cg = c: "class_g = '${c}'";
      boolAttrs = names: val: lib.genAttrs names (_: val);
      hasNvidia =
        osConfig != null && builtins.elem "nvidia" (osConfig.services.xserver.videoDrivers or [ ]);
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
            "_GTK_FRAME_EXTENTS@"
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
            "_GTK_FRAME_EXTENTS@"
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
          unredir-if-possible = false;
          xrender-sync-fence = hasNvidia;
        };

        fade = true;
        fadeDelta = 5;
        fadeSteps = [
          0.03
          0.03
        ];
      };

      systemd.user.services.picom = lib.mkIf config.services.picom.enable {
        Unit = {
          StartLimitIntervalSec = 30;
          StartLimitBurst = 3;
        };
        Service.Restart = lib.mkForce "on-failure";
      };
    };
}
