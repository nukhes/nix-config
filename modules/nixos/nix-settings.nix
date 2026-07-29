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
    allow-import-from-derivation = false;
    fallback = false;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  nix.extraOptions = ''
    max-jobs = 0
  '';
}
