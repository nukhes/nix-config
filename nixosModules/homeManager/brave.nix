{ pkgs, lib, config, ... }: {

  options = {
    brave.enable = lib.mkEnableOption "enables brave";
  };

  config = lib.mkIf config.brave.enable {
    programs.brave = {
      enable = true;
      package = pkgs.brave;
    };
  };

}
