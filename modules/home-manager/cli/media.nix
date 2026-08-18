{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs.stdenv) isLinux;
  inherit (config.home) homeDirectory;

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
    ++ lib.optionals isLinux [
      playerctl
    ];

  home.shellAliases = commonAliases // (if isLinux then linuxAliases else darwinAliases);

  age.secrets = {
    spotify-player = {
      file = "${homeDirectory}/.nix-config/secrets/spotify-player.age";
      path = "${homeDirectory}/.config/spotify-player/app.toml";
      mode = "0600";
    };
  };

  services.playerctld.enable = lib.mkIf isLinux true;
}
