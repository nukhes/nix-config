{ pkgs, ... }:

{
  home.packages = with pkgs; [
    hledger
    hledger-ui
  ];

  home.shellAliases = {
    hl   = "hledger";
    hlui = "hledger-ui";

    hl-balanco  = "hledger bal assets";
    hl-gastos = "hledger bal expenses --forecast";
  };
}
