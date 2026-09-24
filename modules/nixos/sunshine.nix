_:

{
  nixos.modules.x99 =
    {
      config,
      pkgs,
      lib,
      ...
    }:

    let
      xrandr = "${pkgs.xrandr}/bin/xrandr";

      setStreamResolution = pkgs.writeShellScript "sunshine-set-resolution" ''
        OUTPUT=$(${xrandr} --query | grep ' connected' | head -1 | awk '{print $1}')

        MODE=$(${xrandr} --query | sed -n "/$OUTPUT/,/^\S/p" | grep -oP '1440x900\S*' | head -1)

        if [ -z "$MODE" ]; then
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

          encoder = "nvenc";
          min_fps_factor = 1;
          min_threads = 2;

          nv_preset = "p4";
          nv_tune = "ull";
          nv_rc = "cbr";

          audio_sink = "auto";

          channels = 1;

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

      users.users."user".extraGroups = [
        "uinput"
        "input"
      ];
    };
}
