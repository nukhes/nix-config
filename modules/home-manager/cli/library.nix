{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (config.home) homeDirectory;
  libraryPath = "${homeDirectory}/library";

  papis-scihub = pkgs.python3Packages.buildPythonPackage rec {
    pname = "papis-scihub";
    version = "0.1.3";
    pyproject = true;

    src = pkgs.fetchFromGitHub {
      owner = "papis";
      repo = "scripts";
      rev = "4a7b88b811e8d09c5905a7c9c4c3b24110431170";
      hash = "sha256-4GpCDGvOHxlv0pnVezq2Fbu0H+9atAMb7b0tN/wE/Vo=";
    } + "/papis-scihub";

    build-system = [ pkgs.python3Packages.setuptools ];

    dependencies = with pkgs.python3Packages; [
      papis
      beautifulsoup4
      python-doi
    ];

    doCheck = false;
  };

  papisWithScihub = pkgs.papis.overridePythonAttrs (old: {
    propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ [ papis-scihub ];
  });

  library-add-paper = pkgs.writeShellApplication {
    name = "library-add-paper";
    runtimeInputs = [ papisWithScihub ];
    text = ''
      if [[ $# -lt 1 ]]; then
        echo "Usage: library-add-paper <doi>"
        exit 1
      fi
      papis -l papers add --from scihub --git "$1"
    '';
  };

  library-add-book = pkgs.writeShellApplication {
    name = "library-add-book";
    runtimeInputs = [ papisWithScihub ];
    text = ''
      read -rp "Title: " title
      if [[ -z "$title" ]]; then
        echo "Title is required."
        exit 1
      fi

      read -rp "Author: " author
      if [[ -z "$author" ]]; then
        echo "Author is required."
        exit 1
      fi

      read -rp "Year: " year
      if [[ -z "$year" ]]; then
        echo "Year is required."
        exit 1
      fi

      read -rp "PDF file path: " filepath
      if [[ -z "$filepath" ]]; then
        echo "PDF file path is required."
        exit 1
      fi

      filepath=$(eval echo "$filepath")

      if [[ ! -f "$filepath" ]]; then
        echo "File not found: $filepath"
        exit 1
      fi

      papis -l books add --git \
        --set title "$title" \
        --set author "$author" \
        --set year "$year" \
        "$filepath"
    '';
  };

  papis-export-mobi = pkgs.writeShellApplication {
    name = "papis-export-mobi";
    runtimeInputs = with pkgs; [
      papisWithScihub
      calibre
      coreutils
      gawk
      gnugrep
      rofi
    ];
    text = ''
      all_libs=$(papis list --libraries 2>/dev/null | awk '$1 != "settings" {print $1}')
      library=$(echo "$all_libs" | rofi -dmenu -i -p "Library")
      if [[ -z "$library" ]]; then
          echo "No library selected. Aborting."
          exit 1
      fi

      books=$(papis -l "$library" list --all --format '{doc[title]} - {doc[author]}')
      if [[ -z "$books" ]]; then
          echo "No entries found in library '$library'."
          exit 1
      fi
      chosen=$(echo "$books" | rofi -dmenu -i -p "Book")
      if [[ -z "$chosen" ]]; then
          echo "No book selected. Aborting."
          exit 1
      fi

      file=$(papis -l "$library" list --file "$chosen" | grep -viE '\.(yaml|bib|txt)$' | head -n1)
      if [[ -z "$file" || ! -f "$file" ]]; then
          echo "No file found for '$chosen'."
          exit 1
      fi

      base=$(basename "$file")
      name="''${base%.*}"
      ext="''${file##*.}"
      output="$HOME/''${name}.mobi"
      if [[ "''${ext,,}" == "mobi" ]]; then
          cp "$file" "$output"
          echo "Copied to $output"
      else
          ebook-convert "$file" "$output"
          echo "Converted to $output"
      fi
    '';
  };
in
{
  home.packages = [
    library-add-paper
    library-add-book
    papis-export-mobi
  ];

  programs.papis = {
    enable = true;
    package = papisWithScihub;
    settings = {
      picktool = "rofi";
      opener = "${pkgs.zathura}/bin/zathura";
    };
    libraries = {
      papers = {
        isDefault = true;
        settings = {
          dir = "${libraryPath}/papers";
          file-name = "{doc[year]}_{doc[title]}.pdf";
          header-format = "{doc[title]} ({doc[author]}) [{doc[year]}]";
        };
      };
      books = {
        isDefault = false;
        settings = {
          dir = "${libraryPath}/books";
          file-name = "{doc[author]}_{doc[title]}.pdf";
          header-format = "{doc[title]} - {doc[author]}";
        };
      };
    };
  };

  home.activation.createLibraryDirs = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "${libraryPath}" ]; then
      export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -o StrictHostKeyChecking=accept-new"
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone git@github.com:nukhes/library.git "${libraryPath}"
    fi
  '';

  home.shellAliases = {
    cite = "papis -l papers export --format bibtex | xclip -selection clipboard";
    library = "papis open";
  };
}
