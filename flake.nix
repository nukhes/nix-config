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

    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix.url = "github:nix-community/stylix/release-26.05";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      flake-parts,
      nixpkgs,
      nix-darwin,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      flake =
        let
          specialArgs = {
            inherit inputs;
            modules = ./modules;
            secrets = ./secrets;
          };
        in
        {
          nixosConfigurations.hackbook = nixpkgs.lib.nixosSystem {
            inherit specialArgs;

            modules = [
              { nixpkgs.hostPlatform = "x86_64-linux"; }
              ./modules/hosts/hackbook/configuration.nix
              inputs.stylix.nixosModules.stylix
              inputs.nixos-hardware.nixosModules.apple-macbook-air-7
              inputs.agenix.nixosModules.default
              inputs.nix-flatpak.nixosModules.nix-flatpak
              inputs.home-manager.nixosModules.home-manager
            ];
          };

          darwinConfigurations.darwin = nix-darwin.lib.darwinSystem {
            inherit specialArgs;

            modules = [
              { nixpkgs.hostPlatform = "aarch64-darwin"; }
              ./modules/hosts/darwin/configuration.nix
              inputs.agenix.darwinModules.default
              inputs.home-manager.darwinModules.home-manager
            ];
          };
        };
    };
}
