{
  description = "NixOS Configuration for Pedro Henrique";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nur.url = "github:nix-community/NUR";
    agenix.url = "github:ryantm/agenix";
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    home-manager = {
      url = "github:nix-community/home-manager";
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

    stylix.url = "github:nix-community/stylix";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    let
      # Auto-import: recursively find all .nix files under ./modules,
      # excluding *.pkg.nix files (callPackage exceptions).
      importModules =
        dir:
        let
          listRecursive =
            prefix:
            let
              entries = builtins.readDir prefix;
              names = builtins.attrNames entries;
              process =
                name:
                let
                  path = prefix + "/${name}";
                  type = entries.${name};
                in
                if type == "directory" then
                  listRecursive path
                else if
                  type == "regular"
                  && builtins.match ".*\\.nix" name != null
                  && builtins.match ".*\\.pkg\\.nix" name == null
                then
                  [ path ]
                else
                  [ ];
            in
            builtins.concatLists (builtins.map process names);
        in
        listRecursive dir;
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      imports = importModules ./modules;
    };
}
