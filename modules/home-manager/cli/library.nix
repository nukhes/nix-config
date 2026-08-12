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
    $DRY_RUN_CMD git clone git@github.com:nukhes/library.git "${libraryPath}"
  '';

  home.shellAliases = {
    "pp" = "papis -l papers";
    "ppadd" = "papis -l papers add --from doi";
    "ppopen" = "papis -l papers open";
    "ppbib" = "papis -l papers export --format bibtex | xclip -selection clipboard";
    "bk" = "papis -l books";
    "bkadd" = "papis -l books add";
    "bkopen" = "papis -l books open";
    "lib" = "papis open";
  };
}
