{ config, pkgs, ... }:

{
  # ensure my wacom tablet is associated with the internal laptop display
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="input", ATTRS{name}=="Wacom One by Wacom S Pen Pen (0)", RUN+="${pkgs.writeShellScript "mapear_wacom" ''
      sleep 1
      
      # Encontra o usuário logado na sessão gráfica
      USER=$(who | grep '(:0)' | awk '{print $1}' | head -n 1)
      if [ -z "$USER" ]; then
        USER=$(ls /home | head -n 1)
      fi

      export DISPLAY=:0
      export XAUTHORITY=/home/$USER/.Xauthority
      
      /run/current-system/sw/bin/xinput map-to-output "Wacom One by Wacom S Pen Pen (0)" eDP-1
    ''}"
  '';
}
