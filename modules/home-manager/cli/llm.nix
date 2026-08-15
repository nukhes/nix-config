{
  config,
  inputs,
  pkgs,
  ...
}:

let
  inherit (config.xdg) configHome;
in
{
  home.packages = [
    inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-cli
  ];

  programs.claude-code = {
    enable = true;
    configDir = "${configHome}/claude";
    settings.theme = "dark";
  };
}
