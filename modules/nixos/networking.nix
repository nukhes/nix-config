{
  secrets,
  ...
}:
{
  networking.hostName = "hackbook";
  networking.networkmanager.wifi.powersave = false;
  networking.networkmanager.enable = true;
  networking.wireless.enable = true;

  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
  ];

  age.secrets.eduroam = {
    file = "${secrets}/eduroam.age";
    path = "/etc/NetworkManager/system-connections/eduroam.nmconnection";
    mode = "0600";
    owner = "root";
    group = "root";
    symlink = false;
  };
}
