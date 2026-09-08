{
  config,
  pkgs,
  lib,
  ...
}:

let
  xrandr = "${pkgs.xrandr}/bin/xrandr";

  # ── Resolution switching scripts for Moonlight streaming ─────────
  # Dynamically detects the active output (single-monitor setup)
  # and switches to 1440x900 (16:10 — hackbook native aspect ratio).

  setStreamResolution = pkgs.writeShellScript "sunshine-set-resolution" ''
    OUTPUT=$(${xrandr} --query | grep ' connected' | head -1 | awk '{print $1}')

    # Check if a 1440x900 mode already exists for this output
    MODE=$(${xrandr} --query | sed -n "/$OUTPUT/,/^\S/p" | grep -oP '1440x900\S*' | head -1)

    if [ -z "$MODE" ]; then
      # CVT modeline for 1440x900 @ 60 Hz
      ${xrandr} --newmode "1440x900_60.00" 106.50 1440 1528 1672 1904 900 903 909 934 -hsync +vsync 2>/dev/null || true
      ${xrandr} --addmode "$OUTPUT" "1440x900_60.00" 2>/dev/null || true
      MODE="1440x900_60.00"
    fi

    ${xrandr} --output "$OUTPUT" --mode "$MODE"
  '';

  restoreResolution = pkgs.writeShellScript "sunshine-restore-resolution" ''
    OUTPUT=$(${xrandr} --query | grep ' connected' | head -1 | awk '{print $1}')
    ${xrandr} --output "$OUTPUT" --preferred
  '';
in
{
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;

    package = pkgs.sunshine.override {
      cudaSupport = true;
    };

    settings = {
      sunshine_name = "x99";

      # ── Video / Encoder ──────────────────────────────────────
      encoder = "nvenc";
      min_fps_factor = 1;
      min_threads = 2;

      # NVENC quality tuning
      nv_preset = "p4"; # balanced speed/quality (p1=fastest … p7=best)
      nv_tune = "ull"; # ultra-low-latency
      nv_rc = "cbr"; # constant bitrate for consistent stream

      # ── Audio ────────────────────────────────────────────────
      audio_sink = "auto"; # auto-detect PipeWire/PulseAudio sink

      # ── Network ─────────────────────────────────────────────
      channels = 1; # simultaneous stream channels

      # ── Logging ─────────────────────────────────────────────
      min_log_level = "info";
    };

    applications = {
      env = {
        PATH = "$(PATH):$(HOME)/.local/bin";
      };
      apps = [
        {
          name = "Desktop";
          image-path = "desktop.png";
          auto-detach = "true";
          prep-cmd = [
            {
              do = "${setStreamResolution}";
              undo = "${restoreResolution}";
            }
          ];
        }
        {
          name = "Steam Big Picture";
          detached = [
            "${lib.getExe pkgs.steam} -bigpicture"
          ];
          image-path = "steam.png";
          auto-detach = "true";
          prep-cmd = [
            {
              do = "${setStreamResolution}";
              undo = "${restoreResolution}";
            }
          ];
        }
      ];
    };
  };

  # The NixOS sunshine module already enables:
  #   - hardware.uinput.enable
  #   - services.avahi (publish + userServices)
  #   - firewall ports (when openFirewall = true)
  # So we only need to add the user to the required groups.

  users.users."user".extraGroups = [
    "uinput" # virtual input device access
    "input" # physical input device access
  ];
}
