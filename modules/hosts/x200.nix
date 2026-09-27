{ config, inputs, ... }:

{
  flake.nixosConfigurations.x200 = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      { nixpkgs.hostPlatform = "x86_64-linux"; }
      config.nixos.modules.common
      config.nixos.modules.laptop
      config.nixos.modules.x200

      inputs.stylix.nixosModules.stylix
      inputs.agenix.nixosModules.default
      inputs.nix-flatpak.nixosModules.nix-flatpak
      inputs.home-manager.nixosModules.home-manager
    ];
  };
}
