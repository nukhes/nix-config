{ pkgs, lib, ... }:

let
  colors = {
    bg = "$bg";
    fg = "$fg";
    primary = "$color4";
    alert = "$color1";
    disabled = "$color8";
    indicator = "$color5";
  };

  xrandr-update = pkgs.writeShellScript "xrandr-update" ''
    if xrandr | grep -q "HDMI-1 connected"; then
      xrandr --output eDP-1 --off --output HDMI-1 --auto --rate 60 --above eDP-1
    else
      xrandr --auto
    fi
    systemctl --user restart polybar.service
  '';

  screenshot = pkgs.writeShellScript "screenshot" ''
    maim -s | xclip -selection clipboard -t image/png
  '';

  mod = "Mod4";

  mkColorSet = border: text: indicator: childBorder: {
    inherit
      border
      text
      indicator
      childBorder
      ;
    background = colors.bg;
  };

  dirs = {
    j = "left";
    k = "down";
    l = "up";
    semicolon = "right";
    Left = "left";
    Down = "down";
    Up = "up";
    Right = "right";
  };

  resizeMap = {
    left = "shrink width";
    down = "grow height";
    up = "shrink height";
    right = "grow width";
  };

  genKeys =
    prefix: action: lib.mapAttrs' (k: v: lib.nameValuePair "${prefix}${k}" "${action} ${v}") dirs;
  focusKeys = genKeys "${mod}+" "focus";
  moveKeys = genKeys "${mod}+Shift+" "move";
  resizeKeys = lib.mapAttrs' (
    k: dir: lib.nameValuePair k "resize ${resizeMap.${dir}} 10 px or 10 ppt"
  ) dirs;

  wsKeys =
    builtins.foldl'
      (
        acc: n:
        let
          ws = if n == 0 then "10" else toString n;
        in
        acc
        // {
          "${mod}+${toString n}" = "workspace number ${ws}";
          "${mod}+Shift+${toString n}" = "move container to workspace number ${ws}";
        }
      )
      { }
      [
        1
        2
        3
        4
      ];

in
{
  home.packages = with pkgs; [
    brightnessctl
    maim
    xclip
  ];

  xsession.windowManager.i3 = {
    enable = true;
    extraConfig = ''
      set_from_resource $bg background #000000
      set_from_resource $fg foreground #ffffff
      set_from_resource $color1 color1 #ff0000
      set_from_resource $color2 color2 #00ff00
      set_from_resource $color3 color3 #ffff00
      set_from_resource $color4 color4 #0000ff
      set_from_resource $color5 color5 #ff00ff
      set_from_resource $color6 color6 #00ffff
      set_from_resource $color8 color8 #888888
    '';
    config = {
      startup = [
        {
          command = "systemctl --user restart polybar";
          always = true;
          notification = false;
        }
      ];
      modifier = mod;
      fonts = {
        names = [ "Iosevka Nerd Font" ];
        size = 11.0;
      };
      floating.modifier = mod;
      bars = [ ];
      window = {
        border = 0;
        titlebar = false;
      };

      colors = lib.mkForce {
        focused = mkColorSet colors.primary colors.fg colors.indicator colors.primary;
        focusedInactive = mkColorSet colors.disabled colors.fg colors.indicator colors.disabled;
        unfocused = mkColorSet colors.disabled colors.fg colors.indicator colors.disabled;
        urgent = mkColorSet colors.alert colors.alert colors.disabled colors.alert;
        placeholder = mkColorSet colors.disabled colors.fg colors.disabled colors.disabled;
        background = colors.bg;
      };

      keybindings = lib.mkOptionDefault (
        focusKeys
        // moveKeys
        // wsKeys
        // {
          "${mod}+Return" = "exec alacritty";
          "${mod}+Shift+b" = "exec firefox";
          "${mod}+Shift+o" = "exec obsidian";
          "${mod}+Shift+c" = "exec code";
          "${mod}+Shift+f" = "exec alacritty -e yazi";
          "${mod}+Shift+s" = "exec --no-startup-id ${screenshot}";
          "${mod}+space" = "exec rofi -show drun";
          "${mod}+Shift+space" =
            "exec --no-startup-id xdg-open \"\$(rg --files --hidden --glob '!.*' ~ | rofi -dmenu -i -p 'files:')\"";
          "${mod}+p" = "exec ${xrandr-update}";

          "XF86MonBrightnessUp" = "exec --no-startup-id brightnessctl set +5%";
          "XF86MonBrightnessDown" = "exec --no-startup-id brightnessctl set 5%-";

          "XF86AudioRaiseVolume" = "exec --no-startup-id wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 10%+";
          "XF86AudioLowerVolume" = "exec --no-startup-id wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-";
          "XF86AudioMute" = "exec --no-startup-id wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          "XF86AudioMicMute" = "exec --no-startup-id wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";

          "${mod}+q" = "kill";
          "${mod}+h" = "split h";
          "${mod}+v" = "split v";
          "${mod}+f" = "fullscreen toggle";
          "${mod}+s" = "layout stacking";
          "${mod}+w" = "layout tabbed";
          "${mod}+e" = "layout toggle split";
          "${mod}+m" = "focus mode_toggle";
          "${mod}+a" = "focus parent";

          "${mod}+Shift+q" = "exec i3-lock | systemctl suspend";
          "${mod}+Shift+r" = "restart";
          "${mod}+Shift+e" = "exec \"i3-nagbar -t warning -m 'exit i3?' -B 'yes, exit i3' 'i3-msg exit'\"";
          "${mod}+r" = "mode \"resize\"";
        }
      );

      modes.resize = resizeKeys // {
        Return = "mode \"default\"";
        Escape = "mode \"default\"";
        "${mod}+r" = "mode \"default\"";
      };
    };
  };
}
