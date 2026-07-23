{
  config,
  pkgs,
  lib,
  ...
}:
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

  xrandr-update = pkgs.writeShellScript "xrandr-update" ''
     # This script control two xrandr states, single and dual-monitor
     if xrandr | grep -q "HDMI-1 connected"; then
       xrandr --output eDP-1 --auto --output HDMI-1 --auto --rate 60 --above eDP-1
     else
       xrandr --auto --rate 60
    fi

    sleep 1

    xinput map-to-output "Wacom One by Wacom S Pen stylus" eDP-1
    xinput map-to-output "Wacom One by Wacom S Pen Pen (0)" eDP-1 
  '';

  mod = "Mod4";
  refresh_i3status = "killall -SIGUSR1 i3status";
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

      window = {
        border = 0;
        titlebar = true;
      };

      floating = {
        modifier = "${mod}";
      };

      colors = {
        focused = {
          border = colors.lavender;
          background = colors.base;
          inherit (colors) text;
          indicator = colors.rosewater;
          childBorder = colors.lavender;
        };
        focusedInactive = {
          border = colors.overlay0;
          background = colors.base;
          inherit (colors) text;
          indicator = colors.rosewater;
          childBorder = colors.overlay0;
        };
        unfocused = {
          border = colors.overlay0;
          background = colors.base;
          inherit (colors) text;
          indicator = colors.rosewater;
          childBorder = colors.overlay0;
        };
        urgent = {
          border = colors.peach;
          background = colors.base;
          text = colors.peach;
          indicator = colors.overlay0;
          childBorder = colors.peach;
        };
        placeholder = {
          border = colors.overlay0;
          background = colors.base;
          inherit (colors) text;
          indicator = colors.overlay0;
          childBorder = colors.overlay0;
        };
        background = colors.base;
      };

      keybindings = lib.mkOptionDefault {
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

        "XF86AudioRaiseVolume" =
          "exec --no-startup-id wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 10%+ && ${refresh_i3status}";
        "XF86AudioLowerVolume" =
          "exec --no-startup-id wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%- && ${refresh_i3status}";
        "XF86AudioMute" =
          "exec --no-startup-id wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && ${refresh_i3status}";
        "XF86AudioMicMute" =
          "exec --no-startup-id wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && ${refresh_i3status}";
        "${mod}+j" = "focus left";
        "${mod}+k" = "focus down";
        "${mod}+l" = "focus up";
        "${mod}+semicolon" = "focus right";
        "${mod}+Left" = "focus left";
        "${mod}+Down" = "focus down";
        "${mod}+Up" = "focus up";
        "${mod}+Right" = "focus right";
        "${mod}+q" = "kill";

        "${mod}+Shift+j" = "move left";
        "${mod}+Shift+k" = "move down";
        "${mod}+Shift+l" = "move up";
        "${mod}+Shift+semicolon" = "move right";
        "${mod}+Shift+Left" = "move left";
        "${mod}+Shift+Down" = "move down";
        "${mod}+Shift+Up" = "move up";
        "${mod}+Shift+Right" = "move right";

        "${mod}+h" = "split h";
        "${mod}+v" = "split v";
        "${mod}+f" = "fullscreen toggle";
        "${mod}+s" = "layout stacking";
        "${mod}+w" = "layout tabbed";
        "${mod}+e" = "layout toggle split";
        "${mod}+m" = "focus mode_toggle";
        "${mod}+a" = "focus parent";

        "${mod}+1" = "workspace number 1";
        "${mod}+2" = "workspace number 2";
        "${mod}+3" = "workspace number 3";
        "${mod}+4" = "workspace number 4";
        "${mod}+5" = "workspace number 5";
        "${mod}+6" = "workspace number 6";
        "${mod}+7" = "workspace number 7";
        "${mod}+8" = "workspace number 8";
        "${mod}+9" = "workspace number 9";
        "${mod}+0" = "workspace number 10";

        "${mod}+Shift+1" = "move container to workspace number 1";
        "${mod}+Shift+2" = "move container to workspace number 2";
        "${mod}+Shift+3" = "move container to workspace number 3";
        "${mod}+Shift+4" = "move container to workspace number 4";
        "${mod}+Shift+5" = "move container to workspace number 5";
        "${mod}+Shift+6" = "move container to workspace number 6";
        "${mod}+Shift+7" = "move container to workspace number 7";
        "${mod}+Shift+8" = "move container to workspace number 8";
        "${mod}+Shift+9" = "move container to workspace number 9";
        "${mod}+Shift+0" = "move container to workspace number 10";

        "${mod}+Shift+r" = "restart";
        "${mod}+Shift+e" =
          "exec \"i3-nagbar -t warning -m 'do you really want to exit i3?' -B 'yes, exit i3' 'i3-msg exit'\"";

        "${mod}+r" = "mode \"resize\"";
      };

      modes = {
        resize = {
          "j" = "resize shrink width 10 px or 10 ppt";
          "k" = "resize grow height 10 px or 10 ppt";
          "l" = "resize shrink height 10 px or 10 ppt";
          "semicolon" = "resize grow width 10 px or 10 ppt";
          "Left" = "resize shrink width 10 px or 10 ppt";
          "Down" = "resize grow height 10 px or 10 ppt";
          "Up" = "resize shrink height 10 px or 10 ppt";
          "Right" = "resize grow width 10 px or 10 ppt";
          "Return" = "mode \"default\"";
          "Escape" = "mode \"default\"";
          "${mod}+r" = "mode \"default\"";
        };
      };

      bars = [ ];

      window.commands = [
        {
          command = "border pixel 0";
          criteria = {
            class = "^.*";
          };
        }
      ];
    };
  };
}
