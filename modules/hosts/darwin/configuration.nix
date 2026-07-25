{ pkgs, inputs, modules, secrets, ... }:

{
  services.nix-daemon.enable = true;
  nix.settings.experimental-features = "nix-command flakes";

  # Check nix-darwin docs
  system.stateVersion = 5;

  networking.hostName = "darwin";
  networking.computerName = "darwin";

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

      home.username = "pedro";
      home.homeDirectory = "/Users/pedro";
      home.stateVersion = "26.05";
    };
  };

  homebrew = {
    enable = true;
    onActivation.autoUpdate = true;
    onActivation.cleanup = "zap"; 

    casks = [
      "spotify"
      "discord"
      "firefox"
      "obsidian"
      "google-chrome"
      "visual-studio-code"
    ];
  };
}
