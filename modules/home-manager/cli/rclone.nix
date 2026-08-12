{
  config,
  pkgs,
  ...
}:

{
  home.packages = [ pkgs.rclone ];
  age.secrets.rclone = {
    file = "${config.home.homeDirectory}/.nix-config/secrets/rclone.age";
    path = "${config.home.homeDirectory}/.config/rclone/rclone.conf";
    mode = "0600";
  };
}
