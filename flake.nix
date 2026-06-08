{
	description = "NixOS Configuration for Pedro Henrique";
	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
		nur.url = "github:nix-community/NUR";
    agenix.url = "github:ryantm/agenix";
		home-manager = {
			url = "github:nix-community/home-manager/release-26.05";
			inputs.nixpkgs.follows = "nixpkgs"; 
		};
	};

	outputs = { self, nixpkgs, nur, home-manager, agenix, ... }@inputs: {

		nixosConfigurations.hackbook = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";

			specialArgs = { inherit inputs; };

			modules = [
				agenix.nixosModules.default
				./configuration.nix
				./hosts/hackbook/configuration.nix

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
		
			];
		};
	};

}
