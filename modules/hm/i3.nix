_:

{
  hm.modules.common =
    { pkgs, lib, ... }:

    let
      colors = {
        bg = "$bg";
        fg = "$fg";
        primary = "$color4";
        alert = "$color1";
        disabled = "$color8";
        indicator = "#3a3a3a";
      };

      screenshot = pkgs.writeShellApplication {
        name = "screenshot";
        runtimeInputs = with pkgs; [
          maim
          xclip
          rofi
          imagemagick
          alacritty
          coreutils
        ];
        text = ''
          SHOT_DIR="$(mktemp -d /tmp/screenshots.XXXXXX)"
          declare -a SHOTS=()

          if ! maim -s "$SHOT_DIR/shot-1.png" 2>/dev/null; then
            rm -rf "$SHOT_DIR"
            exit 0
          fi
          SHOTS+=("$SHOT_DIR/shot-1.png")

          while true; do
            count="''${#SHOTS[@]}"
            choice="$(
              printf 'copiar\ncapturar mais\nenviar ao gemini\nenviar ao ollama (local)\n' \
                | rofi -dmenu -i -p "print ($count):" -lines 4
            )" || {
              rm -rf "$SHOT_DIR"
              exit 0
            }

            case "$choice" in
              copiar)
                if [ "$count" -eq 1 ]; then
                  xclip -selection clipboard -t image/png < "''${SHOTS[0]}"
                else
                  magick "''${SHOTS[@]}" -append png:- | xclip -selection clipboard -t image/png
                fi
                rm -rf "$SHOT_DIR"
                exit 0
                ;;
              "capturar mais")
                next=$((count + 1))
                next_file="$SHOT_DIR/shot-$next.png"
                if maim -s "$next_file" 2>/dev/null; then
                  SHOTS+=("$next_file")
                else
                  rm -f "$next_file"
                fi
                ;;
              "enviar ao gemini")
                if prompt="$(rofi -dmenu -p "gemini ($count img):" -lines 0)"; then
                  declare -a args=(-d "$SHOT_DIR")
                  for s in "''${SHOTS[@]}"; do
                    args+=(-i "$s")
                  done
                  if [ -n "$prompt" ]; then
                    args+=(-- "$prompt")
                  fi
                  exec alacritty --class gemini-repl -T "gemini" -e gemini-repl "''${args[@]}"
                fi
                ;;
              "enviar ao ollama (local)")
                if prompt="$(rofi -dmenu -p "ollama ($count img):" -lines 0)"; then
                  declare -a args=(-m "ollama:gemma3:4b" -d "$SHOT_DIR")
                  for s in "''${SHOTS[@]}"; do
                    args+=(-i "$s")
                  done
                  if [ -n "$prompt" ]; then
                    args+=(-- "$prompt")
                  fi
                  exec alacritty --class gemini-repl -T "gemini" -e gemini-repl "''${args[@]}"
                fi
                ;;
              *)
                rm -rf "$SHOT_DIR"
                exit 0
                ;;
            esac
          done
        '';
      };

      gemini-rofi = pkgs.writeShellApplication {
        name = "gemini-rofi";
        runtimeInputs = with pkgs; [
          rofi
          alacritty
        ];
        text = ''
          prompt="$(rofi -dmenu -p "gemini:" -lines 0)" || exit 0
          if [ -n "$prompt" ]; then
            exec alacritty --class gemini-repl -T "gemini" -e gemini-repl -- "$prompt"
          else
            exec alacritty --class gemini-repl -T "gemini" -e gemini-repl
          fi
        '';
      };

      solid-bg = pkgs.runCommand "solid-bg.png" {
        nativeBuildInputs = [ pkgs.imagemagick ];
      } "magick -size 3840x2160 xc:'#070707' $out";

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

      wsKeys = builtins.foldl' (
        acc: n:
        let
          ws = if n == 0 then "10" else toString n;
        in
        acc
        // {
          "${mod}+${toString n}" = "workspace number ${ws}";
          "${mod}+Shift+${toString n}" = "move container to workspace number ${ws}";
        }
      ) { } (lib.range 0 9);

    in
    {
      home.packages = with pkgs; [
        brightnessctl
        maim
        xclip
        feh
        snixembed
        libnotify
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
            {
              command = "snixembed &";
              always = true;
              notification = false;
            }
            {
              command = "feh --bg-fill '${solid-bg}'";
              always = true;
              notification = false;
            }
          ];
          modifier = mod;
          fonts = {
            names = [ "Iosevka Nerd Font" ];
          };
          floating.modifier = mod;
          bars = [ ];
          gaps = {
            inner = 10;
            outer = 5;
            smartGaps = true;
            smartBorders = "off";
          };

          window = {
            border = 1;
            titlebar = false;
            commands = [
              {
                criteria = {
                  class = "^gemini-repl$";
                };
                command = "floating enable, resize set 960 640, move position center";
              }
            ];
          };

          colors = lib.mkForce {
            focused = mkColorSet "#3a3a3a" colors.fg colors.indicator "#3a3a3a";
            focusedInactive = mkColorSet "#1c1c1c" colors.fg colors.indicator "#1c1c1c";
            unfocused = mkColorSet "#1c1c1c" colors.fg colors.indicator "#1c1c1c";
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
              "${mod}+Shift+s" = "exec --no-startup-id ${lib.getExe screenshot}";
              "${mod}+Shift+g" = "exec --no-startup-id ${lib.getExe gemini-rofi}";
              "${mod}+space" = "exec rofi -show drun";
              "${mod}+Shift+space" =
                "exec --no-startup-id xdg-open \"\$(rg --files --hidden --glob '!.*' ~ | rofi -dmenu -i -p 'files:')\"";

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

              "${mod}+d" = "floating toggle";

              "${mod}+Shift+q" = "exec i3-lock";
              "${mod}+Shift+r" = "restart";
              "${mod}+Shift+e" =
                "exec \"i3-nagbar -t warning -m 'exit i3?' -B 'yes, exit i3' 'loginctl terminate-session $XDG_SESSION_ID'\"";
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
    };
}
