{
  config,
  inputs,
  pkgs,
  ...
}:
{
  home.packages = [
    inputs.antigravity-nix.packages.${pkgs.system}.google-antigravity-cli
  ];

  programs.claude-code = {
    enable = true;
    configDir = "${config.xdg.configHome}/claude";
    settings.theme = "dark";
  };
}
