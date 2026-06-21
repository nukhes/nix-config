{
  config,
  pkgs,
  ...
}:
let
  inherit (pkgs) lib;
  findNixFiles =
    dir:
    let
      contents = builtins.readDir dir;
      filesAndDirs = lib.mapAttrsToList (
        name: type:
        let
          path = dir + "/${name}";
        in
        if type == "directory" then
          findNixFiles path
        else if type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix" then
          [ path ]
        else
          [ ]
      ) contents;
    in
    lib.flatten filesAndDirs;
in
{
  imports = findNixFiles ./.;
}
