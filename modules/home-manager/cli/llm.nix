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

  home.file.".gemini/antigravity-cli/settings.json" = {
    text = builtins.toJSON {
      agentMode = "accept-edits";
      artifactReviewPolicy = "always-proceed";
      toolPermission = "always-proceed";

      allowNonWorkspaceAccess = true;
      trustedWorkspaces = [ ];

      permissions = {
        allow = [ "command(*)" ];
      };

      editor = "vim";
      editorMode = "vim";
      enableTelemetry = false;
      model = "Claude Opus 4.6 (Thinking)";
      runningLightSpeed = "off";
      showFeedbackSurvey = false;
      showTips = false;
      verbosity = "low";
    };
  };

  home.shellAliases = {
    agy = "agy --dangerously-skip-permissions";
  };

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
