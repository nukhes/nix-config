_:

{
  hm.modules.common =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      calibrePkg = pkgs.calibre;
      # Para suporte a arquivos .cbr (RAR), substitua a linha acima por:
      # calibrePkg = pkgs.calibre.override { unrarSupport = true; };
      #
      # Obs.: o unrar é um pacote unfree. Este repositório já habilita
      # `nixpkgs.config.allowUnfree = true;` em `modules/nixos/nix-settings.nix`.
      # Se usar este módulo em um host sem allowUnfree global, habilite:
      #   nixpkgs.config.allowUnfree = true;
      # ou permita apenas o pacote unrar via `nixpkgs.config.allowUnfreePredicate`.

      calibreConfigDir = "${config.xdg.configHome}/calibre";
      calibreLibraryDir = "${config.xdg.dataHome}/calibre-library";

      configureCalibreScript =
        pkgs.writers.writePython3 "configure-calibre" { flakeIgnore = [ "E501" ]; }
          ''
            import json
            import os
            import subprocess
            import sys
            import tempfile

            CONFIG_DIR = sys.argv[1]
            LIBRARY_DIR = sys.argv[2]
            CALIBREDB_BIN = sys.argv[3]

            MINIMAL_TOOLBAR = [
                "Add Books",
                "Edit Metadata",
                "Convert Books",
                "View",
                "Remove Books",
                "Preferences",
            ]

            DESIRED_CONFIGS = {
                "global.py.json": {
                    "library_path": LIBRARY_DIR,
                },
                "dynamic.pickle.json": {
                    "welcome_wizard_was_run": True,
                },
                "gui.json": {
                    "action-layout-toolbar": MINIMAL_TOOLBAR,
                    "action-layout-toolbar-device": MINIMAL_TOOLBAR,
                    "action-layout-toolbar-child": [],
                    "action-layout-menubar": [],
                    "action-layout-menubar-device": [],
                    "show_splash_screen": False,
                    "show_layout_buttons": False,
                    "show_vl_tabs": False,
                    "main_window_central_widget_state": {
                        "layout": "wide",
                        "wide_visibility": {
                            "tag_browser": False,
                            "book_details": False,
                            "book_list": True,
                            "cover_browser": False,
                            "quick_view": False,
                        },
                        "narrow_visibility": {
                            "tag_browser": False,
                            "book_details": False,
                            "book_list": True,
                            "cover_browser": False,
                            "quick_view": False,
                        },
                    },
                },
                "gui.py.json": {
                    "gui_layout": "wide",
                    "disable_animations": True,
                    "systray_icon": False,
                    "disable_tray_notification": True,
                },
            }


            def deep_merge(base, overrides):
                merged = dict(base)
                for key, value in overrides.items():
                    if isinstance(value, dict) and isinstance(merged.get(key), dict):
                        merged[key] = deep_merge(merged[key], value)
                    else:
                        merged[key] = value
                return merged


            def load_json_dict(path):
                if not os.path.exists(path):
                    return {}
                try:
                    with open(path, "r", encoding="utf-8") as fh:
                        content = fh.read().strip()
                    if not content:
                        return {}
                    data = json.loads(content)
                    return data if isinstance(data, dict) else {}
                except (OSError, ValueError) as exc:
                    print(
                        f"configure-calibre: ignoring invalid JSON in {path}: {exc}",
                        file=sys.stderr,
                    )
                    return {}


            def write_json_atomic(path, data):
                parent = os.path.dirname(path) or "."
                tmp_path = None
                try:
                    fd, tmp_path = tempfile.mkstemp(
                        prefix=".calibre-cfg-", suffix=".tmp", dir=parent
                    )
                    with os.fdopen(fd, "w", encoding="utf-8") as fh:
                        json.dump(data, fh, indent=2, ensure_ascii=False)
                        fh.write("\n")
                    os.chmod(tmp_path, 0o644)
                    os.replace(tmp_path, path)
                    tmp_path = None
                finally:
                    if tmp_path is not None:
                        try:
                            os.unlink(tmp_path)
                        except OSError:
                            pass


            def merge_config_file(path, overrides):
                current = load_json_dict(path)
                updated = deep_merge(current, overrides)
                if os.path.islink(path) or not os.path.exists(path) or updated != current:
                    write_json_atomic(path, updated)


            def ensure_library_initialized():
                metadata_db = os.path.join(LIBRARY_DIR, "metadata.db")
                if os.path.exists(metadata_db):
                    return
                env = os.environ.copy()
                env["CALIBRE_CONFIG_DIRECTORY"] = CONFIG_DIR
                subprocess.run(
                    [CALIBREDB_BIN, "--with-library", LIBRARY_DIR, "list"],
                    env=env,
                    stdout=subprocess.DEVNULL,
                    check=True,
                )


            def main():
                os.makedirs(CONFIG_DIR, exist_ok=True)
                os.makedirs(LIBRARY_DIR, exist_ok=True)
                ensure_library_initialized()
                for filename, overrides in DESIRED_CONFIGS.items():
                    merge_config_file(os.path.join(CONFIG_DIR, filename), overrides)


            if __name__ == "__main__":
                main()
          '';
    in
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      home.packages = [ calibrePkg ];

      home.activation.configureCalibre = config.lib.dag.entryAfter [ "writeBoundary" ] ''
        run ${configureCalibreScript} \
          ${lib.escapeShellArg calibreConfigDir} \
          ${lib.escapeShellArg calibreLibraryDir} \
          ${lib.escapeShellArg "${calibrePkg}/bin/calibredb"}
      '';
    };
}
