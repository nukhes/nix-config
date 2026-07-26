{
  config,
  pkgs,
  ...
}:
{
  age.secrets.gemini-p052 = lib.mkIf pkgs.stdenv.isLinux  {
    file = "${config.home.homeDirectory}/.nix-config/secrets/gemini-p052.age";
    path = "${config.home.homeDirectory}/.config/api-keys/gemini-p052";
    mode = "0600";
  };
}
