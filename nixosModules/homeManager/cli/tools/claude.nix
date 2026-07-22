{ config, pkgs, ... }:

{
  home.packages = [
    pkgs.claude-code
  ];

  home.sessionVariables = {
    ANTHROPIC_BASE_URL = "https://openrouter.ai/api";
    OPENAI_BASE_URL = "https://openrouter.ai/api";
    ANTHROPIC_MODEL = "google/gemini-2.5-flash";
  };

  programs.bash.initExtra = ''
    if [ -f ~/.config/api-keys/openrouter-p052 ]; then
      export OPENROUTER_API_KEY=$(cat ~/.config/api-keys/openrouter-p052)
      export ANTHROPIC_API_KEY=$OPENROUTER_API_KEY
    fi
  '';

  age.secrets.openrouter-p052 = {
    file = "${config.home.homeDirectory}/.nix-config/secrets/openrouter-p052.age";
    path = "${config.home.homeDirectory}/.config/api-keys/openrouter-p052";
    mode = "0600";
  };
}

