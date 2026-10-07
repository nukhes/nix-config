_:
let
  secrets = ../../secrets;
in
{
  nixos.modules.common =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {
      hardware.bluetooth = {
        enable = lib.mkDefault true;
        powerOnBoot = true;
        settings.General = {
          Experimental = true;
          FastConnectable = true;
        };
      };

      services.blueman.enable = lib.mkDefault true;
    };
}
