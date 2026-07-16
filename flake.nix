{
  description = "NixOS Configuration for Pedro Henrique";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nur.url = "github:nix-community/NUR";
    agenix.url = "github:ryantm/agenix";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    {
      # Hackbook Host stands for my Macbook Air 7,2
      nixosConfigurations.hackbook = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        specialArgs = { inherit inputs; };

        modules = [
          inputs.nixos-hardware.nixosModules.apple-macbook-air-7
          inputs.agenix.nixosModules.default
          inputs.nix-flatpak.nixosModules.nix-flatpak
          inputs.home-manager.nixosModules.home-manager

          ./hosts/hackbook/configuration.nix
        ];
      };
    };
}
