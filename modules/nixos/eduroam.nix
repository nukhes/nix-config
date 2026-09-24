_:
let
  secrets = ../../secrets;
in
{
  nixos.modules.laptop = { pkgs, ... }: {
    age.secrets.eduroam = {
      file = "${secrets}/eduroam.age";
      path = "/etc/NetworkManager/system-connections/eduroam.nmconnection";
      mode = "0600";
      owner = "root";
      group = "root";
      symlink = false;
    };
  };
}
