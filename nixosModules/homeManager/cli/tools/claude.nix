{ config, pkgs, ... }:

{
  home.packages = [
    pkgs.claude-code
  ];

  home.sessionVariables = {
    ANTHROPIC_BASE_URL = "https://openrouter.ai/api";
    ANTHROPIC_API_KEY = "";
    ANTHROPIC_MODEL = "anthropic/claude-3.5-sonnet";
  };

  programs.bash.initExtra = ''
    if [ -f ~/.config/openrouter/token ]; then
      export ANTHROPIC_AUTH_TOKEN=$(cat ~/.config/api-keys/openrouter-p052)
    fi
  '';

  age.secrets.openrouter-p052 = {
    file = "${config.home.homeDirectory}/.nix-config/secrets/openrouter-p052.age";
    path = "${config.home.homeDirectory}/.config/api-keys/openrouter-p052";
    mode = "0600";
  };
}

