{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    spotify-player
    playerctl
  ];

  services.playerctld.enable = true;

  home.shellAliases = {
    splay = "spotify-player";
    snext = "playerctl -p spotify-player next";
    sprev = "playerctl -p spotify-player previous";
    spause = "playerctl -p spotify-player play-pause";
  };

  age.secrets.spotify-player = {
    file = ../../secrets/spotify-player.age;
    path = "${config.home.homeDirectory}/.config/spotify-player/app.toml";
    mode = "0600";
  };
}

