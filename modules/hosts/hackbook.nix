{ config, inputs, ... }:

{
  flake.nixosConfigurations.hackbook = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      { nixpkgs.hostPlatform = "x86_64-linux"; }
      config.nixos.modules.common
      config.nixos.modules.laptop
      config.nixos.modules.hackbook
      inputs.nixos-hardware.nixosModules.apple-macbook-air-7
      inputs.stylix.nixosModules.stylix
      inputs.agenix.nixosModules.default
      inputs.nix-flatpak.nixosModules.nix-flatpak
      inputs.home-manager.nixosModules.home-manager
    ];
  };
}
