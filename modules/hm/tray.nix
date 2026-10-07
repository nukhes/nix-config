{ lib, ... }:

{
  hm.modules.common =
    {
      lib,
      osConfig ? null,
      ...
    }:
    let
      hasBluetooth = osConfig != null && (osConfig.hardware.bluetooth.enable or false);
      hasWifi =
        osConfig != null
        && (
          (osConfig.networking.wifi.enable or false)
          || (osConfig.networking.networkmanager.wifi.powersave or null != null)
        );
    in
    {
      # Bluetooth tray applet (blueman-applet) for hosts with Bluetooth
      services.blueman-applet = {
        enable = lib.mkIf hasBluetooth true;
      };

      # WiFi tray applet (nm-applet) for hosts with WiFi
      services.network-manager-applet = {
        enable = lib.mkIf hasWifi true;
      };

      systemd.user.services = {
        blueman-applet.serviceConfig.Restart = lib.mkIf hasBluetooth "on-failure";
        network-manager-applet.serviceConfig.Restart = lib.mkIf hasWifi "on-failure";
      };
    };
}
