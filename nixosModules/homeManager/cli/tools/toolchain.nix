{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    asdf-vm
    cargo
    gcc
    rustc
    lua
    luarocks
  ];
}
