{ pkgs, ... }: {
  home.packages = [
    (pkgs.qgis.override {
      extraPythonPackages = ps: [
        ps.numpy
        ps.pandas
        ps.requests
      ];
    })
  ];
}
