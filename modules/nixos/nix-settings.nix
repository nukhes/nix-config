{ inputs, ... }:
{
  nixpkgs = {
    config.allowUnfree = true;
    overlays = [ inputs.nur.overlays.default ];
  };

  documentation.enable = false;
  documentation.nixos.enable = false;
  documentation.man.enable = false;

  nix.settings = {
    max-jobs = "auto";
    allow-import-from-derivation = false;
    fallback = false;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
}
