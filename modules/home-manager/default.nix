{
  pkgs,
  ...
}:
{
  imports = [
    ./cli
    ./i3wm
    ./programs
  ];

  config = {
    home.username = "user";
    home.stateVersion = "26.05";
    home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/user" else "/home/user";
  };
}
