{
	description = "NixOS Configuration for Pedro Henrique";
	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    agenix.url = "github:ryantm/agenix";
		home-manager = {
			url = "github:nix-community/home-manager/release-26.05";
			inputs.nixpkgs.follows = "nixpkgs"; 
		};
	};

	outputs = { self, nixpkgs, home-manager, agenix, ... }: {
		nixosConfigurations.hackbook = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
            specialArgs = {
              agenixModule = agenix.nixosModules.default;
            };
			modules = [
				./configuration.nix
				./hosts/hackbook/configuration.nix
				home-manager.nixosModules.home-manager
				{
					home-manager = {
						useGlobalPkgs = true;
						useUserPackages = true;
						users.user = import ./hosts/hackbook/home.nix;
						backupFileExtension = "backup";
					};
				}
			];
		};
	};
}
