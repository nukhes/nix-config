{ pkgs, ... }:

{
  home.packages = with pkgs; [
    hledger
    hledger-ui
  ];

  home.shellAliases = {
    hl   = "hledger";
    hlui = "hledger-ui";

    hl-balanco  = "hledger bal --forecast";
    hl-print  = "hledger print --forecast";
    hl-registro = "hledger register --forecast";

    hl-gastos = "hledger bal expenses --forecast";
    hl-ra     = "hledger bal assets:unicamp:RA --forecast";

    hl-hoje = "hledger register --forecast date:today";
    hl-mes  = "hledger bal --forecast date:thismonth";
    hl-prox = "hledger register --forecast date:today-2026/12/31";
  };
}
