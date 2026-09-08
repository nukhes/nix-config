{ pkgs, ... }:

{
  # Moonlight - Game Streaming Client
  environment.systemPackages = with pkgs; [
    moonlight-qt
  ];
}
