let
  user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFow+cxbnFZR24093m8AhvL3ZZks5Wnzvm1/ftbq64aM user@hackbook";
  hackbook = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILYfofle0qvKOY5geXIKsiyXTO87QDR9vMgrgAXj+5UC root@nixos";
  x99 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO6dfj/4f5PwyaikK3B8t8yFoKP90HUDY7pEh2ej54/z root@x99";
  publicKeys = [
    user
    hackbook
    x99
  ];
in
builtins.listToAttrs (
  map
    (name: {
      name = "secrets/${name}.age";
      value.publicKeys = publicKeys;
    })
    [
      "eduroam"
      "rclone"
      "vdirsyncer"
      "gemini-p052"
      "openrouter-p052"
      "spotify-player"
      "borg"
      "tailscale-authkey"
      "syncthing-x99-key"
      "syncthing-x99-cert"
      "syncthing-hackbook-key"
      "syncthing-hackbook-cert"
    ]
)
