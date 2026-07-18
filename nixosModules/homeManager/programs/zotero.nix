{ pkgs, ... }:

{
  home.packages = [
    pkgs.zotero
  ];

  programs.firefox.profiles.default-profile.extensions = [
    pkgs.nur.repos.rycee.firefox-addons.zotero-connector
  ];
}

