{ config, pkgs, ... }:
let
  zaiKeyHelper = pkgs.writeShellScript "zai-api-key-helper" ''
    cat "$HOME/.secrets/zai-api-key"
  '';
in
{
  programs.claude-code = {
    enable = true;
    configDir = "${config.xdg.configHome}/claude";
    settings = {
      theme = "dark";
      apiKeyHelper = "${zaiKeyHelper}";
      env = {
        ANTHROPIC_BASE_URL = "https://api.z.ai/api/anthropic";
        ANTHROPIC_DEFAULT_SONNET_MODEL = "glm-4.7-flash";
        ANTHROPIC_DEFAULT_HAIKU_MODEL = "glm-4.5-flash";
        ANTHROPIC_DEFAULT_OPUS_MODEL = "glm-4.7-flash";
      };
    };
  };
}
