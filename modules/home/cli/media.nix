{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    sox
    mpv
    ani-cli

    playerctl
    spotify-player
  ];

  services.playerctld.enable = true;

  home.shellAliases = {
    splay = "spotify_player";
    snext = "playerctl -p spotify_player next";
    sprev = "playerctl -p spotify_player previous";
    spause = "playerctl -p spotify_player play-pause";
  };

  age.secrets.spotify-player = {
    file = "${config.home.homeDirectory}/.nix-config/secrets/spotify-player.age";
    path = "${config.home.homeDirectory}/.config/spotify-player/app.toml";
    mode = "0600";
  };
}
