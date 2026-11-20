_:

{
  # Zotero no nixpkgs atual ainda empacota o runtime firefox-esr-140 (EOL em 2026-10-13).
  # Exceção co-localizada aqui para fácil remoção quando o nixpkgs migrar para o próximo ESR.
  nixos.modules.common = _: {
    nixpkgs.config.permittedInsecurePackages = [
      "firefox-esr-140-bin-unwrapped-140.17.0esr"
    ];
  };

  hm.modules.common =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      zoteroRootDir = "${config.home.homeDirectory}/.zotero/zotero";
      zoteroLibraryDir = "${config.home.homeDirectory}/.local/share/zotero-library";

      # Contorno temporário (remover junto com a exceção do firefox-esr-140 acima):
      # pkgs.zotero baixa `firefox-onecrl` via web.archive.org (não presente no cache
      # binário porque o firefox-esr-140 está EOL). Como web.archive.org está dando
      # timeout, mantemos o `defaults/settings/security-state/onecrl.json` já embutido
      # no próprio Firefox ESR, igual ao modo `quick_build` do Zotero.
      zoteroPkg =
        (pkgs.zotero.override {
          fetchurl =
            args:
            if (args.name or "") == "firefox-onecrl" then
              pkgs.writeText "firefox-onecrl-unused" ""
            else
              pkgs.fetchurl args;
        }).overrideAttrs
          (old: {
            postPatch = (old.postPatch or "") + ''
              if [ -f app/scripts/fetch_onecrl ]; then
                cat > app/scripts/fetch_onecrl <<'EOF'
              #!${pkgs.runtimeShell}
              exit 0
              EOF
                chmod +x app/scripts/fetch_onecrl
              fi
            '';
          });

      configureZoteroScript =
        pkgs.writers.writePython3 "configure-zotero" { flakeIgnore = [ "E501" ]; }
          ''
            import configparser
            import json
            import os
            import sys
            import tempfile

            ZOTERO_ROOT = sys.argv[1]
            LIBRARY_DIR = sys.argv[2]
            PROFILES_INI = os.path.join(ZOTERO_ROOT, "profiles.ini")
            DEFAULT_PROFILE_NAME = "default"

            DEFAULT_PROFILES_INI_CONTENT = (
                "[General]\n"
                "StartWithLastProfile=1\n"
                "Version=2\n"
                "\n"
                "[Profile0]\n"
                f"Name={DEFAULT_PROFILE_NAME}\n"
                "IsRelative=1\n"
                f"Path={DEFAULT_PROFILE_NAME}\n"
                "Default=1\n"
            )

            USER_PREFS = [
                # Diretório de dados (evita criar ~/Zotero)
                ("extensions.zotero.useDataDir", True),
                ("extensions.zotero.dataDir", LIBRARY_DIR),
                # Pular telas de boas-vindas, guidance, lembretes de sync e changelog
                ("extensions.zotero.firstRun2", False),
                ("extensions.zotero.firstRun.skipFirefoxProfileCheck", True),
                ("extensions.zotero.firstRunGuidance", False),
                ("extensions.zotero.changelogViewed", "99.0"),
                ("extensions.zotero.sync.reminder.setUp.enabled", False),
                # Privacidade e zero telemetria
                ("toolkit.telemetry.enabled", False),
                ("toolkit.telemetry.unified", False),
                ("datareporting.healthreport.uploadEnabled", False),
                ("app.shield.optoutstudies.enabled", False),
                # Performance, updates gerenciados pelo Nix e UI limpa
                ("toolkit.cosmeticAnimations.enabled", False),
                ("ui.prefersReducedMotion", 1),
                ("app.update.enabled", False),
                ("app.update.auto", False),
                ("extensions.update.enabled", False),
                ("extensions.zotero.openReaderInNewWindow", False),
            ]


            def write_text_atomic(path, content):
                if not os.path.islink(path) and os.path.exists(path):
                    try:
                        with open(path, "r", encoding="utf-8") as fh:
                            if fh.read() == content:
                                return
                    except OSError:
                        pass

                parent = os.path.dirname(path) or "."
                tmp_path = None
                try:
                    fd, tmp_path = tempfile.mkstemp(
                        prefix=".zotero-cfg-", suffix=".tmp", dir=parent
                    )
                    with os.fdopen(fd, "w", encoding="utf-8") as fh:
                        fh.write(content)
                    os.chmod(tmp_path, 0o644)
                    os.replace(tmp_path, path)
                    tmp_path = None
                finally:
                    if tmp_path is not None:
                        try:
                            os.unlink(tmp_path)
                        except OSError:
                            pass


            def resolve_profile_dir(section):
                path = section.get("Path", "").strip()
                if not path:
                    return None
                is_relative = section.get("IsRelative", "1").strip() == "1"
                return os.path.join(ZOTERO_ROOT, path) if is_relative else path


            def detect_existing_profile_dir():
                if not os.path.exists(PROFILES_INI):
                    return None

                parser = configparser.ConfigParser(interpolation=None)
                try:
                    parser.read(PROFILES_INI, encoding="utf-8")
                except (OSError, configparser.Error) as exc:
                    print(
                        f"configure-zotero: ignoring unreadable {PROFILES_INI}: {exc}",
                        file=sys.stderr,
                    )
                    return None

                profiles = [
                    parser[name]
                    for name in parser.sections()
                    if name.startswith("Profile")
                ]
                if not profiles:
                    return None

                # 1. Respeita seção [Install*] (perfil padrão vinculado à instalação)
                for name in parser.sections():
                    if name.startswith("Install"):
                        install_default = parser[name].get("Default", "").strip()
                        if install_default:
                            for profile in profiles:
                                if profile.get("Path", "").strip() == install_default:
                                    resolved = resolve_profile_dir(profile)
                                    if resolved:
                                        return resolved
                            if os.path.isabs(install_default):
                                return install_default
                            return os.path.join(ZOTERO_ROOT, install_default)

                # 2. Caso contrário, procura [Profile*] marcado com Default=1
                for profile in profiles:
                    if profile.get("Default", "").strip() == "1":
                        resolved = resolve_profile_dir(profile)
                        if resolved:
                            return resolved

                # 3. Fallback: primeiro perfil definido
                return resolve_profile_dir(profiles[0])


            def ensure_profile_dir():
                existing = detect_existing_profile_dir()
                if existing:
                    os.makedirs(existing, exist_ok=True)
                    return existing

                write_text_atomic(PROFILES_INI, DEFAULT_PROFILES_INI_CONTENT)
                profile_dir = os.path.join(ZOTERO_ROOT, DEFAULT_PROFILE_NAME)
                os.makedirs(profile_dir, exist_ok=True)
                return profile_dir


            def render_user_js():
                lines = [
                    "// Managed declaratively by Home Manager (modules/hm/zotero.nix)",
                    "// Changes here are re-applied by Zotero on every startup.",
                ]
                for key, value in USER_PREFS:
                    lines.append(
                        f"user_pref({json.dumps(key)}, {json.dumps(value)});"
                    )
                return "\n".join(lines) + "\n"


            def main():
                os.makedirs(ZOTERO_ROOT, exist_ok=True)
                os.makedirs(LIBRARY_DIR, exist_ok=True)
                profile_dir = ensure_profile_dir()
                write_text_atomic(os.path.join(profile_dir, "user.js"), render_user_js())


            if __name__ == "__main__":
                main()
          '';
    in
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      home.packages = [ zoteroPkg ];

      home.activation.configureZotero = config.lib.dag.entryAfter [ "writeBoundary" ] ''
        run ${configureZoteroScript} \
          ${lib.escapeShellArg zoteroRootDir} \
          ${lib.escapeShellArg zoteroLibraryDir}
      '';
    };
}
