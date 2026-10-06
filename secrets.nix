let
  user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFow+cxbnFZR24093m8AhvL3ZZks5Wnzvm1/ftbq64aM user@hackbook";
  hackbook = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILYfofle0qvKOY5geXIKsiyXTO87QDR9vMgrgAXj+5UC root@nixos";
  x99 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO6dfj/4f5PwyaikK3B8t8yFoKP90HUDY7pEh2ej54/z root@x99";
  x200 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJiBiF7JHy4xNzti3jK+tqJ7newzhmsvFl9f+NUZIgB7 root@nixos";
  publicKeys = [
    user
    hackbook
    x99
    x200
  ];
in
builtins.listToAttrs (
  map
    (path: {
      name = "secrets/${path}.age";
      value.publicKeys = publicKeys;
    })
    [
      "wifi/eduroam"

      "syncthing/x99/key"
      "syncthing/x99/cert"
      "syncthing/x200/key"
      "syncthing/x200/cert"
      "syncthing/hackbook/key"
      "syncthing/hackbook/cert"

      "google/common/borg"
      "google/common/rclone"
      "google/common/vdirsyncer"

      "google/henriquealvesp052/app-password"
      "google/henriquealvesp052/gemini-api"
      "google/henriquealvesp052/openrouter-api"

      "vpn/tailscale/nukhes/key"
    ]
)
