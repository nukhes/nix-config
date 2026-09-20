{ ... }:

{
  hm.modules.common = { pkgs, ... }: {
    home = {
      username = "user";
      stateVersion = "26.05";
      homeDirectory = if pkgs.stdenv.isDarwin then "/Users/user" else "/home/user";
    };

    stylix.targets = {
      xresources.enable = true;
      feh.enable = false;
      firefox.profileNames = [ "default-profile" ];
    };
  };
}
