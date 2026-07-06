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
    {
      self,
      nixpkgs,
      nur,
      home-manager,
      agenix,
      nixos-hardware,
      nix-flatpak,
      ...
    }@inputs:
    {
      # Hackbook Host stands for my Macbook Air 7,2
      nixosConfigurations.hackbook = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        specialArgs = { inherit inputs; };

        modules = [
          nixos-hardware.nixosModules.apple-macbook-air-7
          ./hosts/hackbook/configuration.nix
          agenix.nixosModules.default
          nix-flatpak.nixosModules.nix-flatpak

          # Home-Manager
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.user.imports = [
                agenix.homeManagerModules.default
                ./home.nix
              ];
              backupFileExtension = "backup";
            };
          }
          # End Home-Manager

          # Nix User Repositories
          {
            nixpkgs.overlays = [
              (final: prev: {
                nur = import nur {
                  nurpkgs = prev;
                  pkgs = prev;
                };
              })
            ];
          }
          # End Nix User Repositories
        ];
      };
    };
}
