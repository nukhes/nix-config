_:

{
  hm.modules.common =
    { pkgs, ... }:
    let
      normalizePdfs = pkgs.writeShellApplication {
        name = "normalize-pdfs";

        runtimeInputs = [
          pkgs.findutils
          pkgs.qpdf
        ];

        text = ''
          set -euo pipefail

          print_usage() {
            echo "Usage: $(basename "$0") <directory>" >&2
          }

          if [ "$#" -ne 1 ]; then
            print_usage
            exit 1
          fi

          target_directory="$1"

          if [ ! -d "$target_directory" ]; then
            print_usage
            exit 1
          fi

          while IFS= read -r -d $'\0' pdf_file; do
            qpdf \
              --replace-input \
              --linearize \
              --compress-streams=y \
              --recompress-flate \
              --compression-level=9 \
              --object-streams=generate \
              --optimize-images \
              --remove-unreferenced-resources=yes \
              "$pdf_file"
          done < <(find "$target_directory" -type f -iname "*.pdf" -print0)
        '';
      };
    in
    {
      home.packages = [
        normalizePdfs
      ];
    };
}
