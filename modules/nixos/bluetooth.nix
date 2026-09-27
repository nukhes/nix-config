_:
let
  secrets = ../../secrets;
in
{
  nixos.modules.common = { pkgs, config, ... }: {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings.General = {
        Experimental = true;
        FastConnectable = true;
      };
    };

    services.blueman.enable = true;
  };
}
