{ config, pkgs, ... }:

{
  imports = [
    ./usb-hook.nix
  ];

  services.xserver.wacom.enable = true;

  services.usb-hook = {
    enable = true;
    script = '' 
      export DISPLAY=:0
      MY_USER="user"
      USER_ID=$(${pkgs.coreutils}/bin/id -u $MY_USER)
      export XAUTHORITY="/run/user/$USER_ID/.lyxauth"
      ${pkgs.coreutils}/bin/sleep 3
      ${pkgs.sudo}/bin/sudo -u $MY_USER env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY ${pkgs.xinput}/bin/xinput map-to-output "Wacom One by Wacom S Pen stylus" eDP-1
    '';
  };
}
