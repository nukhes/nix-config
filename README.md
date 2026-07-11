# nix
NixOS Configuration for Pedro Henrique hosts
```bash
git clone git@github.com:nukhes/nix.git ~/.nix-config

# You can use alternative mirrors
# git clone git@gitlab.com:nukhes/nix-config.git ~/.nix-config
# git clone git@codeberg.org:nukhes/nix-config.git ~/.nix-config

# Build the proper host (ATM just 'hackbook' works as hostname)
sudo nixos-rebuild switch --flake ~/.nix-config#$(hostname)
```
