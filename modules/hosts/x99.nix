{ config, inputs, ... }:

{
  flake.nixosConfigurations.x99 = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      { nixpkgs.hostPlatform = "x86_64-linux"; }
      config.nixos.modules.common
      config.nixos.modules.desktop
      config.nixos.modules.gaming
      config.nixos.modules.x99

      inputs.stylix.nixosModules.stylix
      inputs.agenix.nixosModules.default
      inputs.nix-flatpak.nixosModules.nix-flatpak
      inputs.home-manager.nixosModules.home-manager
    ];
  };
}
