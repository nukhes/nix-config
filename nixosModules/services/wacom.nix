{ config, pkgs, ... }:
let
  mapWacomScript = pkgs.writeShellScriptBin "map-wacom" ''
    sleep 2

    X_USER=$(${pkgs.coreutils}/bin/who | ${pkgs.gnugrep}/bin/grep '(:0)' | ${pkgs.gawk}/bin/awk '{print $1}' | ${pkgs.coreutils}/bin/head -n 1)
    if [ -z "$X_USER" ]; then
      X_USER=$(${pkgs.coreutils}/bin/ls /home | ${pkgs.coreutils}/bin/head -n 1)
    fi

    USER_ID=$(${pkgs.coreutils}/bin/id -u "$X_USER")

    export DISPLAY=:0
    if [ -f "/home/$X_USER/.Xauthority" ]; then
      export XAUTHORITY=/home/$X_USER/.Xauthority
    else
      export XAUTHORITY=/run/user/$USER_ID/gdm/Xauthority
    fi

    ${pkgs.xinput}/bin/xinput map-to-output "Wacom One by Wacom S Pen stylus" eDP-1
  '';
in
{
  services.xserver.wacom.enable = true;

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="input", ATTRS{name}=="Wacom One by Wacom S Pen Pen (0)", TAG+="systemd", ENV{SYSTEMD_WANTS}+="map-wacom.service"
  '';

  systemd.services.map-wacom = {
    description = "Map Wacom tablet to eDP-1 display";
    serviceConfig = {
      Type = "simple";
      ExecStart = "${mapWacomScript}/bin/map-wacom";
      User = "root";
    };
  };
}