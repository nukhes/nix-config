{ config, inputs, ... }:

{
  flake.darwinConfigurations.darwin = inputs.nix-darwin.lib.darwinSystem {
    modules = [
      { nixpkgs.hostPlatform = "aarch64-darwin"; }
      config.darwin.modules.common
      inputs.agenix.darwinModules.default
      inputs.home-manager.darwinModules.home-manager
    ];
  };
}
