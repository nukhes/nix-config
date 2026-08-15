{
  config,
  pkgs,
  ...
}:

let
  inherit (config.home) homeDirectory;
in
{
  home.packages = with pkgs; [ rclone ];

  age.secrets.rclone = {
    file = "${homeDirectory}/.nix-config/secrets/rclone.age";
    path = "${homeDirectory}/.config/rclone/rclone.conf";
    mode = "0600";
  };
}
