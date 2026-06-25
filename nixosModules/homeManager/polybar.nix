{ config, pkgs, ... }:

{
  services.polybar = {
    enable = true;
    
    package = pkgs.polybar.override {
      i3Support = true;
    };
    
    script = ''
      export POLYBAR_BATTERY=$(ls -1 /sys/class/power_supply | grep -E '^BAT' | head -n 1)
      export POLYBAR_ADAPTER=$(ls -1 /sys/class/power_supply | grep -E '^(AC|AD|ADP)' | head -n 1)
      polybar principal &
    '';

    config = {
      "bar/principal" = {
        width = "100%";
        height = "20pt";
        radius = 0;
        background = "#000000";
        foreground = "#C5C8C6";
        line-size = "1pt";
        border-size = "0pt";
        padding-left = 1;
        padding-right = 2;
        module-margin = 1;
        font-0 = "Iosevka Nerd Font:style=Regular:size=11;2";
        font-1 = "Iosevka Nerd Font:style=Regular:size=14;3";
        modules-left = "i3 xwindow";
        modules-right = "tray internet alsa memory cpu battery date";
        cursor-click = "pointer";
        cursor-scroll = "ns-resize";
        enable-ipc = true;
      };

      "module/i3" = {
        type = "internal/i3";
        pin-workspaces = true;
        show-urgent = true;
        strip-wsnumbers = true;
        index-sort = true;
        enable-click = true;
        enable-scroll = false;
        label-focused = "%name%";
        label-focused-background = "#373B41";
        label-focused-underline = "#F0C674";
        label-focused-padding = 2;
        label-unfocused = "%name%";
        label-unfocused-padding = 2;
        label-urgent = "%name%";
        label-urgent-background = "#A54242";
        label-urgent-padding = 2;
      };

      "module/xwindow" = {
        type = "internal/xwindow";
        label = "%title:0:50:...%";
        label-foreground = "#81A2BE";
      };

      "module/alsa" = {
        type = "internal/alsa";
        format-volume = "<ramp-volume> <label-volume>";
        label-volume = "%percentage%%";
        label-muted = "󰖁 mutado";
        label-muted-foreground = "#707880";
        ramp-volume-0 = "󰕿";
        ramp-volume-1 = "󰖀";
        ramp-volume-2 = "󰕾";
        ramp-volume-foreground = "#B5BD68";
      };

      "module/memory" = {
        type = "internal/memory";
        interval = 2;
        format-prefix = "󰍛 ";
        format-prefix-foreground = "#B294BB";
        label = "%percentage_used%%";
      };

      "module/cpu" = {
        type = "internal/cpu";
        interval = 2;
        format-prefix = "󰻠 ";
        format-prefix-foreground = "#8ABEB7";
        label = "%percentage%%";
      };

      "module/battery" = {
        type = "internal/battery";
        battery = "\${env:POLYBAR_BATTERY:BAT0}";
        adapter = "\${env:POLYBAR_ADAPTER:AC}";
        full-at = 98;
        format-charging = "<label-charging>";
        format-discharging = "<ramp-capacity> <label-discharging>";
        format-full = "<label-full>";
        label-charging = "󰂄 %percentage%%";
        label-charging-foreground = "#8ABEB7";
        label-discharging = "%percentage%%";
        label-discharging-foreground = "#F0C674";
        label-full = "󰁹 %percentage%%";
        label-full-foreground = "#B5BD68";
        ramp-capacity-0 = "󰁻";
        ramp-capacity-1 = "󰁼";
        ramp-capacity-2 = "󰁽";
        ramp-capacity-3 = "󰁾";
        ramp-capacity-4 = "󰁿";
        ramp-capacity-foreground = "#F0C674";
      };

      "module/internet" = {
        type = "internal/network";
        interface-type = "wireless";
        interval = 2;
        format-connected = "<label-connected>";
        format-disconnected = "<label-disconnected>";
        label-connected = "󰤨 %essid% %downspeed%";
        label-connected-foreground = "#8ABEB7";
        label-disconnected = "󰤭 offline";
        label-disconnected-foreground = "#A54242";
      };

      "module/date" = {
        type = "internal/date";
        interval = 1;
        date = "%Y-%m-%d %H:%M:%S";
        label = "󰃰 %date%";
        label-foreground = "#F0C674";
      };

      "module/tray" = {
        type = "internal/tray";
        tray-background = "#000000";
        tray-padding = 2;
      };
    };
  };
}