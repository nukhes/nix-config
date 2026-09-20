{ ... }:

{
  hm.modules.common = { lib, pkgs, ... }: lib.mkIf pkgs.stdenv.isLinux {
    home.packages = with pkgs; [
      (qgis.override {
        extraPythonPackages =
          ps: with ps; [
            numpy
            pandas
            requests
          ];
      })
    ];
  };
}
