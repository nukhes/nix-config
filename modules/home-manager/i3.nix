{ pkgs, lib, ... }:
let
  colors = {
    rosewater = "#f5e0dc";
    peach = "#fab387";
    lavender = "#b4befe";
    text = "#ffffff";
    overlay0 = "#6c7086";
    base = "#000000";
  };

  # Possible Wacom S Pen ids (this shit tablet has a different id every reboot)
  wacomMap =
    lib.concatMapStringsSep "\n" (pen: ''xinput map-to-output "${pen}" eDP-1 2>/dev/null || true'')
      [
        "Wacom One by Wacom S Pen stylus"
        "Wacom One by Wacom S Pen Pen (0)"
      ];

  xrandr-update = pkgs.writeShellScript "xrandr-update" ''
    if xrandr | grep -q "HDMI-1 connected"; then
      xrandr --output eDP-1 --off --output HDMI-1 --auto --rate 60 --above eDP-1
    else
      xrandr --auto --rate 60
    fi
    sleep 1
    ${wacomMap}
  '';

  mod = "Mod4";

  mkColorSet = border: text: indicator: childBorder: {
    inherit
      border
      text
      indicator
      childBorder
      ;
    background = colors.base;
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

      colors = {
        focused = mkColorSet colors.lavender colors.text colors.rosewater colors.lavender;
        focusedInactive = mkColorSet colors.overlay0 colors.text colors.rosewater colors.overlay0;
        unfocused = mkColorSet colors.overlay0 colors.text colors.rosewater colors.overlay0;
        urgent = mkColorSet colors.peach colors.peach colors.overlay0 colors.peach;
        placeholder = mkColorSet colors.overlay0 colors.text colors.overlay0 colors.overlay0;
        background = colors.base;
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
          "${mod}+Shift+s" = "exec --no-startup-id maim -s | xclip -selection clipboard -t image/png";
          "${mod}+space" = "exec rofi -show drun";
          "${mod}+Shift+space" =
            "exec --no-startup-id xdg-open \"\$(rg --files --hidden --glob '!.*' ~ | rofi -dmenu -i -p 'files:')\"";
          "${mod}+p" = "exec ${xrandr-update}";
          "${mod}+Shift+q" = "exec i3-lock | systemctl suspend";

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

          "${mod}+Shift+r" = "restart";
          "${mod}+Shift+e" =
            "exec \"i3-nagbar -t warning -m 'do you really want to exit i3?' -B 'yes, exit i3' 'i3-msg exit'\"";
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
