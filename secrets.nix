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
{
  "secrets/eduroam.age".publicKeys = publicKeys;
  "secrets/rclone.age".publicKeys = publicKeys;
  "secrets/vdirsyncer.age".publicKeys = publicKeys;
  "secrets/gemini-p052.age".publicKeys = publicKeys;
  "secrets/openrouter-p052.age".publicKeys = publicKeys;
  "secrets/spotify-player.age".publicKeys = publicKeys;
  "secrets/borg.age".publicKeys = publicKeys;
  "secrets/tailscale-authkey.age".publicKeys = publicKeys;
  "secrets/syncthing-x99-key.age".publicKeys = publicKeys;
  "secrets/syncthing-x99-cert.age".publicKeys = publicKeys;

  "secrets/syncthing-hackbook-key.age".publicKeys = publicKeys;
  "secrets/syncthing-hackbook-cert.age".publicKeys = publicKeys;
}
