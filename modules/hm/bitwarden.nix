_:

{
  hm.modules.common =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      bwSecretPath = config.age.secrets.bitwarden.path;

      rbwPinentry = pkgs.writeShellScriptBin "pinentry-rbw" ''
        echo "OK Pleased to meet you"
        while read -r line; do
          case "$line" in
            GETPIN*)
              PASS=$(${pkgs.yq-go}/bin/yq -r '.password' "${bwSecretPath}")
              echo "D $PASS"
              echo "OK"
              ;;
            BYE*)
              echo "OK closing connection"
              exit 0
              ;;
            *)
              echo "OK"
              ;;
          esac
        done
      '';
    in
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      home.packages = with pkgs; [
        rbw
      ];

      programs.rbw = {
        enable = true;
        settings = {
          email = "nukhes@protonmail.com";
          base_url = "https://vault.bitwarden.com";
          lock_timeout = 86400;
          pinentry = rbwPinentry;
        };
      };

      systemd.user.services.rbw-unlock = {
        Unit = {
          Description = "Desbloqueia o cofre do Bitwarden (rbw) via agenix";
          After = [ "agenix.service" ];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.rbw}/bin/rbw unlock";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };

      age.secrets = {
        bitwarden = {
          file = "${homeDirectory}/.nix-config/secrets/bitwarden/secrets.age";
          path = "${homeDirectory}/.secrets/bitwarden/secrets.yaml";
          mode = "0600";
        };
      };
    };
}
