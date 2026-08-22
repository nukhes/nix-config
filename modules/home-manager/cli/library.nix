{
  config,
  pkgs,
  ...
}:

let
  inherit (config.home) homeDirectory;
  libraryPath = "${homeDirectory}/library";

  papis-export-mobi = pkgs.writeShellApplication {
    name = "papis-export-mobi";
    runtimeInputs = with pkgs; [ 
      papis 
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
  home.packages = with pkgs; [
    papis
    papis-export-mobi
  ];

  home.file.".config/papis/config".text = ''
    [settings]
    default-library = papers

    [papers]
    dir = ${libraryPath}/papers
    file-name = {doc[year]}_{doc[title]}.pdf
    header-format = {doc[title]} ({doc[author]}) [{doc[year]}]
    opener = ${pkgs.zathura}/bin/zathura
    pick-tool = rofi

    [books]
    dir = ${libraryPath}/books
    file-name = {doc[author]}_{doc[title]}.pdf
    header-format = {doc[title]} - {doc[author]}
    opener = ${pkgs.zathura}/bin/zathura
    pick-tool = rofi
  '';

  home.activation.createLibraryDirs = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "${libraryPath}" ]; then
      export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -o StrictHostKeyChecking=accept-new"
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone git@github.com:nukhes/library.git "${libraryPath}"
    fi
  '';

  home.shellAliases = {
    pp = "papis -l papers";
    ppa = "papis -l papers add --git --from doi";
    ppr = "papis -l papers open";
    ppbib = "papis -l papers export --format bibtex | xclip -selection clipboard";
    bk = "papis -l books";
    bka = "papis -l books add --git";
    bkr = "papis -l books open";
    lib = "papis open";
  };
}
