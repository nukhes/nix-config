{ lib, ... }:

{
  nixos.modules.common =
    { lib, config, ... }:
    {
      options.networking.wifi = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = config.networking.networkmanager.wifi.powersave != null;
          description = "Whether this host has WiFi hardware support.";
        };
      };
    };

  nixos.modules.laptop = _: {
    networking.wifi.enable = true;
  };
}
