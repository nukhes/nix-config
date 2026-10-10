_:

{
  hm.modules.common =
    { config, lib, ... }:
    {
      stylix.targets.rofi.fonts.enable = false;

      programs.rofi = {
        enable = true;
        settings = {
          modi = "drun,run,window";
          show-icons = true;
          drun-display-format = "{name}";
          sidebar-mode = false;
          font = lib.mkIf (config.stylix.enable or false) (
            lib.mkDefault "${config.stylix.fonts.monospace.name} ${toString config.stylix.fonts.sizes.popups}"
          );
        };
      };
    };
}
