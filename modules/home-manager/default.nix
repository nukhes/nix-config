{ pkgs, ... }:

{
  imports = [
    ./cli
    ./i3wm
    ./programs
  ];

  config = {
    home = {
      username = "user";
      stateVersion = "26.05";
      homeDirectory = if pkgs.stdenv.isDarwin then "/Users/user" else "/home/user";
    };

    stylix.targets.xresources.enable = true;
    stylix.targets.firefox.profileNames = [ "default-profile" ];
  };
}
