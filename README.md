# nix
NixOS Configuration for Pedro Henrique
```bash
git clone git@github.com:nukhes/nix.git ~/.nix-config
sudo nixos-rebuild switch --flake ~/.nix-config#$(hostname)
```