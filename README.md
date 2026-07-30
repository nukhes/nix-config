# Nix

NixOS Configuration for Pedro Henrique.

```bash
git clone git@github.com:nukhes/nix-config.git ~/.nix-config

# You can use alternative mirrors
# git clone git@gitlab.com:nukhes/nix-config.git ~/.nix-config
# git clone git@codeberg.org:nukhes/nix-config.git ~/.nix-config

# Build the proper host (ATM just 'hackbook' works as hostname)
sudo nixos-rebuild switch --flake ~/.nix-config#$(hostname)
```

## Home Folder Structure

These folders contains user important data and should be properly backuped.
```bash
~/{src, uni, usr, .zotero}
~/.local/share/{calibre-library, obsidian-vault, zotero}
```
