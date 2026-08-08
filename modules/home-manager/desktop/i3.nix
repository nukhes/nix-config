{ pkgs, lib, ... }:
let
  colors = {
    rosewater = "#f5e0dc";
    flamingo = "#f2cdcd";
    pink = "#f5c2e7";
    mauve = "#cba6f7";
    red = "#f38ba8";
    maroon = "#eba0ac";
    peach = "#fab387";
    yellow = "#f9e2af";
    green = "#a6e3a1";
    teal = "#94e2d5";
    sky = "#89dceb";
    sapphire = "#74c7ec";
    blue = "#89b4fa";
    lavender = "#b4befe";
    text = "#cdd6f4";
    subtext1 = "#bac2de";
    subtext0 = "#a6adc8";
    overlay2 = "#9399b2";
    overlay1 = "#7f849c";
    overlay0 = "#6c7086";
    surface2 = "#585b70";
    surface1 = "#45475a";
    surface0 = "#313244";
    base = "#000000";
    mantle = "#181825";
    crust = "#11111b";
  };

  wacomMap = ''
    xinput map-to-output "Wacom One by Wacom S Pen stylus" eDP-1
    xinput map-to-output "Wacom One by Wacom S Pen Pen (0)" eDP-1
  '';

  xrandr-update = pkgs.writeShellScript "xrandr-update" ''
    if xrandr | grep -q "HDMI-1 connected"; then
      xrandr --output eDP-1 --auto --output HDMI-1 --auto --rate 60 --above eDP-1
    else
      xrandr --auto --rate 60
    fi
    sleep 1
    ${wacomMap}
  '';

  mod = "Mod4";
  refresh_i3status = "killall -SIGUSR1 i3status";
  vol = cmd: "exec --no-startup-id ${cmd} && ${refresh_i3status}";

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

  resizeDirs = {
    j = "shrink width";
    k = "grow height";
    l = "shrink height";
    semicolon = "grow width";
    Left = "shrink width";
    Down = "grow height";
    Up = "shrink height";
    Right = "grow width";
  };

  genKeys =
    prefix: action: lib.mapAttrs' (k: v: lib.nameValuePair "${prefix}${k}" "${action} ${v}") dirs;
  focusKeys = genKeys "${mod}+" "focus";
  moveKeys = genKeys "${mod}+Shift+" "move";
  resizeKeys = lib.mapAttrs' (k: v: lib.nameValuePair k "resize ${v} 10 px or 10 ppt") resizeDirs;

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
        5
        6
        7
        8
        9
        0
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
        titlebar = true;
        commands = [
          {
            command = "border pixel 0";
            criteria.class = "^.*";
          }
        ];
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

          "XF86AudioRaiseVolume" = vol "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 10%+";
          "XF86AudioLowerVolume" = vol "wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-";
          "XF86AudioMute" = vol "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          "XF86AudioMicMute" = vol "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";

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
