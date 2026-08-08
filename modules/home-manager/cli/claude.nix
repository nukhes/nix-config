{
  config,
  pkgs,
  lib,
  ...
}:

let
  secretPath = "${config.home.homeDirectory}/.secrets/zai";
  zaiAlias = "export ANTHROPIC_BASE_URL=\"https://api.z.ai/api/anthropic\" && export ANTHROPIC_AUTH_TOKEN=\"$(cat ${secretPath})\" && claude";
in
{
  programs.claude-code = {
    enable = true;
    configDir = "${config.xdg.configHome}/claude";
    settings.theme = "dark";
  };

  programs.bash.shellAliases.zai = zaiAlias;
  programs.zsh.shellAliases.zai = zaiAlias;

  programs.zsh.enable = lib.mkIf pkgs.stdenv.isDarwin true;

  age.secrets.zai = lib.mkIf pkgs.stdenv.isLinux {
    file = "${config.home.homeDirectory}/.nix-config/secrets/zai.age";
    path = secretPath;
    mode = "0600";
  };
}
