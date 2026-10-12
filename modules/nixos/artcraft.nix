_:

{
  nixos.modules.x99 = _: {
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
