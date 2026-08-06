{ pkgs, ... }:

{
  home.packages = with pkgs; [
    hledger
    hledger-ui
  ];

  home.shellAliases = {
    hl   = "hledger";
    hln  = "hledger balance assets --forecast=thismonth -e tomorrow";
  };
}
