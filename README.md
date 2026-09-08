# Nix

NixOS Configuration for Pedro Henrique.

```bash
# Ensure your SSH key is properly placed at "/etc/ssh/" and "~/.ssh/"
git clone git@github.com:nukhes/nix-config.git ~/.nix-config

# Alternative mirrors
# git clone git@gitlab.com:nukhes/nix-config.git ~/.nix-config
# git clone git@codeberg.org:nukhes/nix-config.git ~/.nix-config

sudo nixos-rebuild switch --flake ~/.nix-config#$(cat /etc/hostname)
```

