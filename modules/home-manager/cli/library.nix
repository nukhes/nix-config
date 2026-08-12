{ config, pkgs, ... }:

let
  libraryPath = "${config.home.homeDirectory}/library";
in
{
  home.packages = with pkgs; [
    papis
  ];

  home.file.".config/papis/config".text = ''
    [settings]
    default-library = papers

    [papers]
    dir = ${libraryPath}/papers
    file-name = {doc[year]}_{doc[title]}.pdf
    header-format = {doc[title]} ({doc[author]}) [{doc[year]}]
    opener = ${pkgs.zathura}/bin/zathura
    pick-tool = fzf

    [books]
    dir = ${libraryPath}/books
    file-name = {doc[author]}_{doc[title]}.pdf
    header-format = {doc[title]} - {doc[author]}
    opener = ${pkgs.zathura}/bin/zathura
    pick-tool = fzf
  '';

  home.activation.createLibraryDirs = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${libraryPath}/papers"
    $DRY_RUN_CMD mkdir -p "${libraryPath}/books"
  '';

  home.shellAliases = {
    "pa"    = "papis -l papers";
    "pa-add" = "papis -l papers add --from doi";
    "pa-open" = "papis -l papers open";
    "pa-bib" = "papis -l papers export --format bibtex | xclip -selection clipboard";
    "bk"      = "papis -l books";
    "bk-add"  = "papis -l books add";
    "bk-open" = "papis -l books open";
    "lib"     = "papis open";
  };
}
