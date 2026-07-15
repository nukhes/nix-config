{ pkgs, config, lib, ... }: {
  
  options = {
    chrome.enable = lib.mkEnableOption "enables chrome";
  };

  config = lib.mkIf config.chrome.enable {
    programs.chromium= {
      enable = true;
      package = pkgs.google-chrome;
    };
  };

}
