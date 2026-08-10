{
  config,
  lib,
  pkgs,
  ...
}:

let
  commonAliases = {
    splay = "spotify_player --cache-folder ~/.secrets/spotify";
  };

  linuxAliases = {
    snext = "playerctl -p spotify_player next";
    sprev = "playerctl -p spotify_player previous";
    spause = "playerctl -p spotify_player play-pause";
  };

  darwinAliases = {
    snext = "spotify_player playback next";
    sprev = "spotify_player playback previous";
    spause = "spotify_player playback play";
  };
in
{
  home.packages =
    with pkgs;
    [
      sox
      mpv
      ani-cli
      spotify-player
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      playerctl
    ];

  home.shellAliases = commonAliases // (if pkgs.stdenv.isLinux then linuxAliases else darwinAliases);

  age.secrets.spotify-player = {
    file = "${config.home.homeDirectory}/.nix-config/secrets/spotify-player.age";
    path = "${config.home.homeDirectory}/.config/spotify-player/app.toml";
    mode = "0600";
  };

  age.secrets.spotify-player-user-token = {
    file = "${config.home.homeDirectory}/.nix-config/secrets/spotify-player-user-token.age";
    path = "${config.home.homeDirectory}/.secrets/spotify/user_client_token.json";
    mode = "0600";
  };

  age.secrets.spotify-player-credentials = {
    file = "${config.home.homeDirectory}/.nix-config/secrets/spotify-player-credentials.age";
    path = "${config.home.homeDirectory}/.secrets/spotify/credentials.json";
    mode = "0600";
  };


  services.playerctld.enable = lib.mkIf pkgs.stdenv.isLinux true;
}
