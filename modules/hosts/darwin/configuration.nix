{
  pkgs,
  inputs,
  modules,
  secrets,
  ...
}:

{
  services.nix-daemon.enable = true;
  nix.settings.experimental-features = "nix-command flakes";

  system.stateVersion = 5;

  networking = {
    hostName = "darwin";
    computerName = "darwin";
  };

  system.defaults = {
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;
    NSGlobalDomain.AppleShowAllExtensions = true;
  };

  users.users.pedro = {
    name = "pedro";
    home = "/Users/pedro";
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs modules secrets; };
    users.pedro = {
      imports = [
        inputs.agenix.homeManagerModules.default
        "${modules}/home-manager"
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
}
