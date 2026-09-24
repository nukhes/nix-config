_:

{
  hm.modules.gaming = { pkgs, ... }: {
    programs.prismlauncher.enable = true;

    programs.java = {
      enable = true;
      package = pkgs.openjdk17;
    };
  };
}
