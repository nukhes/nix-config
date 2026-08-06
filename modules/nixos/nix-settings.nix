{
  config,
  pkgs,
  inputs,
  ...
}:
{
  nixpkgs = {
    config.allowUnfree = true;
    overlays = [ inputs.nur.overlays.default ];
  };

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
