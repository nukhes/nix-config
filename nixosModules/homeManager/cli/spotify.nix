{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    spotify-player
    playerctl
  ];

  services.playerctld.enable = true;

  home.shellAliases = {
    splay = "spotify_player";
    snext = "playerctl -p spotify_player next";
    sprev = "playerctl -p spotify_player previous";
    spause = "playerctl -p spotify_player play-pause";
  };

  age.secrets.spotify-player = {
    file = ../../secrets/spotify-player.age;
    path = "${config.home.homeDirectory}/.config/spotify-player/app.toml";
    mode = "0600";
  };
}
