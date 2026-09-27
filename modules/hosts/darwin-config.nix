{ config, inputs, ... }:

{
  darwin.modules.common = _: {
    nix = {
      enable = true;
      settings.experimental-features = "nix-command flakes";
    };

    system.stateVersion = 5;

    networking = {
      hostName = "darwin";
      computerName = "darwin";
    };

    system.defaults = {
      dock.autohide = true;
      finder.AppleShowAllExtensions = true;
    };

    users.users.pedro = {
      name = "pedro";
      home = "/Users/pedro";
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.pedro = {
        imports = [
          inputs.agenix.homeManagerModules.default
          config.hm.modules.common
        ];
        home = {
          username = "pedro";
          homeDirectory = "/Users/pedro";
          stateVersion = "26.05";
        };
      };
    };

    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = true;
        cleanup = "zap";
      };
      casks = [
        "spotify"
        "discord"
      ];
    };
  };
}
