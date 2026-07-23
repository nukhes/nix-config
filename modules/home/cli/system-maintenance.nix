{
  config,
  pkgs,
  ...
}:
{
  programs.bash.shellAliases = {
      rebuild = "sudo nixos-rebuild switch --flake ${config.home.homeDirectory}/.nix-config#$(hostname)";
      cleanup = "sudo nix-collect-garbage -d && sudo nix-store --optimise -v";
      upgrade = "cd ${config.home.homeDirectory}/.nix-config && nix flake update && sudo nixos-rebuild switch --flake .#$(hostname) && sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +2 && sudo nix-store --gc";
      agenix-add = "nix run github:ryantm/agenix -- --edit";
      agenix-rekey = "nix run github:ryantm/agenix -- --rekey";
      nixfmt-run = "cd ~/.nix-config && nix run nixpkgs#statix -- fix . && nix run nixpkgs#nixfmt-tree -- .";
  };
}
