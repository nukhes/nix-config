let
  user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFow+cxbnFZR24093m8AhvL3ZZks5Wnzvm1/ftbq64aM user@hackbook";
  hackbook = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILYfofle0qvKOY5geXIKsiyXTO87QDR9vMgrgAXj+5UC root@nixos";
  publicKeys = [
    user
    hackbook
  ];
in
{
  "secrets/eduroam.age".publicKeys = publicKeys;
  "secrets/rclone.age".publicKeys = publicKeys;
  "secrets/vdirsyncer.age".publicKeys = publicKeys;
  "secrets/gemini-p052.age".publicKeys = publicKeys;
  "secrets/openrouter-p052.age".publicKeys = publicKeys;
  "secrets/spotify-player.age".publicKeys = publicKeys;
  "secrets/restic.age".publicKeys = publicKeys;
}
