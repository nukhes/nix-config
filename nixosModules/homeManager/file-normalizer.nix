{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.fileNormalizer;

  fileNormalizerScript = pkgs.writeShellApplication {
    name = "file-normalizer";
    runtimeInputs = [ pkgs.coreutils pkgs.gnused ];
    text = ''
      for f in *; do
        [ -f "$f" ] || continue
        
        date_str=$(date -r "$f" +%Y%m%d)
        new_name=$(echo "$f" | tr '[:upper:]' '[:lower:]' | tr ' -' '__' | sed 's/[^a-z0-9_.]//g')
        final_name="''${date_str}_''${new_name}"
        
        if [ "$f" != "$final_name" ]; then
          mv -v "$f" "$final_name"
        fi
      done
    '';
  };
in {
  options.programs.fileNormalizer = {
    enable = mkEnableOption "fileNormalizer utility";
  };

  config = mkIf cfg.enable {
    home.packages = [ fileNormalizerScript ];
  };
}
