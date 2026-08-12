{ pkgs, ... }:
let
  fg = "\${xrdb:foreground:#C5C8C6}";
  bg = "\${xrdb:background:#000000}";
in
{
  services.polybar = {
    enable = true;
    package = pkgs.polybar.override {
      i3Support = true;
      pulseSupport = true;
    };
    script = ''
      export POLYBAR_BATTERY=$(ls -1 /sys/class/power_supply | grep -E '^BAT' | head -n 1)
      export POLYBAR_ADAPTER=$(ls -1 /sys/class/power_supply | grep -E '^(AC|AD|ADP)' | head -n 1)
      polybar main &
    '';
    config = {
      "bar/main" = {
        width = "100%";
        height = "20pt";
        radius = 0;
        background = bg;
        foreground = fg;
        line-size = "1pt";
        border-size = "0pt";
        padding-left = 1;
        padding-right = 2;
        module-margin = 1;
        font-0 = "Iosevka Nerd Font:style=Regular:size=11;2";
        font-1 = "Iosevka Nerd Font:style=Regular:size=14;3";
        modules-left = "i3 xwindow";
        modules-right = "tray pipewire memory cpu battery date";
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
        label-focused-background = bg;
        label-focused-underline = fg;
        label-focused-padding = 2;
        label-unfocused = "%name%";
        label-unfocused-padding = 2;
        label-urgent = "%name%";
        label-urgent-background = bg;
        label-urgent-padding = 2;
      };
      "module/xwindow" = {
        type = "internal/xwindow";
        label = "%title:0:50:...%";
        label-foreground = fg;
      };
      "module/pipewire" = {
        type = "internal/pulseaudio";
        interval = 5;
        use-ui-max = false;
        format-volume = "<ramp-volume> <label-volume>";
        format-muted = "<label-muted>";
        label-volume = "%percentage%%";
        label-muted = "󰖁 muted";
        label-volume-foreground = fg;
        label-muted-foreground = fg;
        ramp-volume-foreground = fg;
        ramp-volume-0 = "";
        ramp-volume-1 = "";
        ramp-volume-2 = "";
      };
      "module/memory" = {
        type = "internal/memory";
        interval = 2;
        format-prefix = "󰍛 ";
        format-prefix-foreground = fg;
        label = "%percentage_used%%";
      };
      "module/cpu" = {
        type = "internal/cpu";
        interval = 2;
        format-prefix = "󰻠 ";
        format-prefix-foreground = fg;
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
        label-discharging = "%percentage%%";
        label-full = "󰁹 %percentage%%";
        label-charging-foreground = fg;
        label-discharging-foreground = fg;
        label-full-foreground = fg;
        ramp-capacity-foreground = fg;
        ramp-capacity-0 = "󰁻";
        ramp-capacity-1 = "󰁼";
        ramp-capacity-2 = "󰁽";
        ramp-capacity-3 = "󰁾";
        ramp-capacity-4 = "󰁿";
      };
      "module/internet" = {
        type = "internal/network";
        interface-type = "wireless";
        interval = 2;
        format-connected = "<label-connected>";
        format-disconnected = "<label-disconnected>";
        label-connected = "󰤨 %essid% %downspeed%";
        label-disconnected = "󰤭 offline";
        label-connected-foreground = fg;
        label-disconnected-foreground = fg;
      };
      "module/date" = {
        type = "internal/date";
        interval = 1;
        date = "%Y-%m-%d %H:%M:%S";
        label = "󰃰 %date%";
        label-foreground = fg;
      };
      "module/tray" = {
        type = "internal/tray";
        tray-background = bg;
        tray-padding = 2;
      };
    };
  };
}
