{
  config,
  pkgs,
  ...
}: {
  services.xserver.wacom.enable = true;

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="input", ATTRS{name}=="Wacom One by Wacom S Pen Pen (0)", RUN+="${pkgs.writeShellScript "mapear_wacom" ''
      (
        sleep 2

        USER=$(${pkgs.coreutils}/bin/who | ${pkgs.gnugrep}/bin/grep '(:0)' | ${pkgs.gawk}/bin/awk '{print $1}' | ${pkgs.coreutils}/bin/head -n 1)
        if [ -z "$USER" ]; then
          USER=$(${pkgs.coreutils}/bin/ls /home | ${pkgs.coreutils}/bin/head -n 1)
        fi

        export DISPLAY=:0

        if [ -f "/home/$USER/.Xauthority" ]; then
          export XAUTHORITY=/home/$USER/.Xauthority
        else
          USER_ID=$(${pkgs.coreutils}/bin/id -u "$USER")
          export XAUTHORITY=/run/user/$USER_ID/gdm/Xauthority
        fi

        ${pkgs.xorg.xinput}/bin/xinput map-to-output "Wacom One by Wacom S Pen stylus" eDP-1
      ) &
    ''}"
  '';
}
