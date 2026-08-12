{
  pkgs,
  ...
}:
{
  programs.vscode.enable = true;
  programs.vscode.profiles.default = {
    userSettings = {
      "telemetry.telemetryLevel" = "off";
      "editor.tabSize" = 2;
      "editor.fontFamily" = "Iosevka";
      "editor.fontSize" = 16;
      "editor.formatOnSave" = true;
      "explorer.confirmDragAndDrop" = false;
      "git.confirmSync" = false;
      "git.autofetch" = true;
      "editor.wordWrap" = "on";
      "breadcrumbs.enabled" = false;
      "editor.stickyScroll.enabled" = false;
      "git.enableSmartCommit" = true;
      "workbench.activityBar.location" = "default";
      "window.commandCenter" = false;
      "workbench.layoutControl.enabled" = false;
      "workbench.startupEditor" = "newUntitledFile";
      "editor.rulers" = [
        80
        120
      ];
      "extensions.ignoreRecommendations" = true;
      "workbench.tree.enableStickyScroll" = false;
      "files.associations" = {
        ".env.*" = "dotenv";
        ".prettierrc" = "json";
        "*.css" = "postcss";
        ".dev.vars" = "dotenv";
        "*.ndjson" = "jsonl";
      };
      "editor.parameterHints.enabled" = false;
      "editor.renderLineHighlight" = "gutter";
      "editor.suggestSelection" = "first";
      "explorer.confirmDelete" = false;
      "terminal.integrated.showExitAlert" = false;
      "workbench.editor.labelFormat" = "short";
      "editor.fontLigatures" = true;
      "editor.semanticHighlighting.enabled" = false;
      "security.workspace.trust.untrustedFiles" = "newWindow";
      "files.exclude" = {
        "**/CVS" = true;
        "**/.DS_Store" = true;
        "**/.hg" = true;
        "**/.svn" = true;
        "**/.git" = true;
        ".vscode" = true;
      };
      "[jsonc]" = {
        "editor.defaultFormatter" = "vscode.json-language-features";
      };
      "[json]" = {
        "editor.defaultFormatter" = "vscode.json-language-features";
      };
      "git.openRepositoryInParentFolders" = "always";
      "workbench.editor.empty.hint" = "hidden";
      "update.showReleaseNotes" = false;
      "security.promptForLocalFileProtocolHandling" = false;
      "editor.hideCursorInOverviewRuler" = true;
      "editor.minimap.enabled" = false;
      "window.titleBarStyle" = "native";
      "editor.scrollbar.vertical" = "hidden";
      "explorer.sortOrder" = "foldersNestsFiles";
      "explorer.fileNesting.patterns" = {
        "package.json" =
          ".eslint*, eslint.config.*, prettier*, tsconfig*, vite*, pnpm-*, bun.lockb, nest*, package-lock*";
        "tailwind.config.*" = "tailwind.config*, postcss.config*";
        ".env.local" = ".env*";
        ".env" = ".env*";
      };
      "explorer.fileNesting.enabled" = true;
      "workbench.statusBar.visible" = false;
      "editor.tokenColorCustomizations" = {
        "textMateRules" = [ ];
      };
      "window.autoDetectColorScheme" = true;
      "liveServer.settings.donotShowInfoMsg" = true;
      "editor.multiCursorLimit" = 50000;
      "window.menuBarVisibility" = "toggle";
      "files.autoSave" = "onFocusChange";
    };
    extensions = with pkgs.vscode-extensions; [
      dbaeumer.vscode-eslint
      ritwickdey.liveserver
      yzhang.markdown-all-in-one
      continue.continue
    ];
  };
}
