{ config, lib, pkgs, ... }:

let
  commonAliases = {
    splay = "spotify_player";
  };

  linuxAliases = {
    snext  = "playerctl -p spotify_player next";
    sprev  = "playerctl -p spotify_player previous";
    spause = "playerctl -p spotify_player play-pause";
  };

  darwinAliases = {
    snext  = "spotify_player playback next";
    sprev  = "spotify_player playback previous";
    spause = "spotify_player playback play";
  };
in
{
  home.packages = with pkgs; [
    sox
    mpv
    ani-cli
    spotify-player
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    playerctl
  ];

  home.shellAliases = commonAliases // (
    if pkgs.stdenv.isLinux then linuxAliases else darwinAliases
  );

  age.secrets.spotify-player = {
    file = "${config.home.homeDirectory}/.nix-config/secrets/spotify-player.age";
    path = "${config.home.homeDirectory}/.config/spotify-player/app.toml";
    mode = "0600";
  };

  services.playerctld.enable = lib.mkIf pkgs.stdenv.isLinux true;
}