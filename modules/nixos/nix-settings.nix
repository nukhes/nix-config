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

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
