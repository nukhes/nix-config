{
  config,
  inputs,
  pkgs,
  ...
}:
let
  inherit (config.home) homeDirectory;
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

  age.secrets.gemini-p052 = {
    file = "${homeDirectory}/.nix-config/secrets/gemini-p052.age";
    path = "${homeDirectory}/.secrets/gemini-p052";
    mode = "0600";
  };
}
