_:

{
  hm.modules.x99 =
    { lib, pkgs, ... }:
    {
      programs.artcraft = {
        enable = true;
        apps = [
          "photocraft"
          "vectorcraft_0_4_0"
          "lightcraft"
          "filmcraft"
          "pdfcraft"
        ];
      };
    };
}
