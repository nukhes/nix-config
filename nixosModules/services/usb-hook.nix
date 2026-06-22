{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.usb-hook;
in
{
  options.services.usb-hook = {
    enable = mkEnableOption "usb-hook that runs a command";

    script = mkOption {
      type = types.lines;
      default = "";
      description = ''
        usb-hook that runs a command
      '';
      example = ''
        echo "[$(date)] new device ($1) connected" >> /var/log/usb-hook.log
      '';
    };
  };

  config = mkIf cfg.enable {
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", TAG+="systemd", ENV{SYSTEMD_WANTS}+="usb-hook@%k.service"
    '';
    systemd.services."usb-hook@" = {
      description = "usb-hook %I";
      after = [ "udev.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "usb-hook-script" cfg.script} %i";
        StandardOutput = "journal";
        StandardError = "journal";
        TimeoutStartSec = 30;
        Restart = "no";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
