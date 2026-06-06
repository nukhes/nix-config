let
  user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFow+cxbnFZR24093m8AhvL3ZZks5Wnzvm1/ftbq64aM user@hackbook";
  hackbook = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILYfofle0qvKOY5geXIKsiyXTO87QDR9vMgrgAXj+5UC root@nixos";
  allKeys = [ user hackbook ];
in
{
  "secrets/eduroam.age".publicKeys = allKeys;
  "secrets/rclone.age".publicKeys = allKeys;
}
