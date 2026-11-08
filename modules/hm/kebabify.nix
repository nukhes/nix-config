_:

{
  hm.modules.common =
    { pkgs, ... }:
    let
      kebabify = pkgs.writeShellApplication {
        name = "kebabify";

        runtimeInputs = [
          pkgs.coreutils
          pkgs.findutils
          pkgs.gnused
        ];

        text = ''
          set -euo pipefail

          yolo=0
          target_dir=""

          for arg in "$@"; do
            if [ "$arg" == "--yolo" ]; then
              yolo=1
            else
              target_dir="$arg"
            fi
          done

          if [ -z "$target_dir" ] || [ ! -d "$target_dir" ]; then
            echo "Usage: $0 <directory> [--yolo]" >&2
            exit 1
          fi

          target_dir="''${target_dir%/}"

          if [ "$yolo" -eq 0 ]; then
            cp -a "$target_dir" "''${target_dir}-old"
          fi

          find "$target_dir" -type f -iname "*.pdf" -print0 | while IFS= read -r -d $'\0' file; do
            dir_name=$(dirname "$file")
            base_name=$(basename "$file" .pdf)

            kebab_name=$(echo "$base_name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g' | sed -E 's/^-+|-+$//g')
            new_file="$dir_name/$kebab_name.pdf"

            if [ "$file" != "$new_file" ]; then
              mv -n "$file" "$new_file"
            fi
          done
        '';
      };
    in
    {
      home.packages = [
        kebabify
      ];
    };
}
