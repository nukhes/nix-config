{
  description = "NixOS Configuration for Pedro Henrique";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nur.url = "github:nix-community/NUR";
    agenix.url = "github:ryantm/agenix";
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05"; 
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch-darwin" ];

      flake = {
        nixosConfigurations.hackbook = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          specialArgs = {
            inherit inputs;
            modules = ./modules;
            secrets = ./secrets;
          };

          modules = [
            ./modules/hosts/hackbook/configuration.nix

            inputs.nixos-hardware.nixosModules.apple-macbook-air-7
            inputs.agenix.nixosModules.default
            inputs.nix-flatpak.nixosModules.nix-flatpak
            inputs.home-manager.nixosModules.home-manager
          ];
        };

        darwinConfigurations.darwin = inputs.nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";

          specialArgs = {
            inherit inputs;
            modules = ./modules;
            secrets = ./secrets;
          };

          modules = [
            ./modules/hosts/darwin/configuration.nix

            inputs.agenix.darwinModules.default
            inputs.home-manager.darwinModules.home-manager
          ];
        };
      };
    };
}
