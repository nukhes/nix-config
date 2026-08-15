_: {
  programs.bash.initExtra = "export GEMINI_API_KEY=\"$(cat \"$HOME/.secrets/gemini-p052\")\"";
  programs.zsh.initExtra = "export GEMINI_API_KEY=\"$(cat \"$HOME/.secrets/gemini-p052\")\"";

  programs.zed-editor = {
    enable = true;

    extensions = [
      "nix"
      "biome"
      "toml"
      "sql"
      "php"
      "latex"
    ];

    userSettings = {
      autosave = "on_focus_change";
      formatter = {
        language_server.name = "biome";
      };
      code_actions_on_format = {
        "source.fixAll.biome" = true;
        "source.organizeImports.biome" = true;
      };
      inlay_hints.enabled = true;
      indent_guides.coloring = "indent_aware";
      vim_mode = false;
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
    };
  };
}
