{ config, lib, ... }:

let
  hostname = config.networking.hostName;

  allDevices = {
    x99 = {
      id = "6XKO7MN-7XE4EDE-BVNJZO4-JGN4TJG-CCLSEBJ-3JNVY2B-PD3ZX6B-MTTQCAC";
    };
    hackbook = {
      id = "5MBTINO-KGSNPN4-RHH4CSA-7VNAOLF-RIIEYEF-5L3OFGP-AYBJVDF-EYNG2QX";
    };
  };

  remoteDevices = lib.filterAttrs (name: _: name != hostname) allDevices;
  remoteDeviceNames = lib.attrNames remoteDevices;
in
{
  services.syncthing = {
    enable = true;
    user = "user";
    group = "users";
    dataDir = "/home/user";
    configDir = "/home/user/.config/syncthing";

    settings = {
      devices = remoteDevices;

      folders = {
        documents = {
          path = "/home/user/documents";
          devices = remoteDeviceNames;
        };
        ics = {
          path = "/home/user/.ics";
          devices = remoteDeviceNames;
        };
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 22000 ];
    allowedUDPPorts = [ 22000 21027 ];
  };

  age.secrets = {
    syncthing-${hostname}-key = {
      file = "${homeDirectory}/.nix-config/secrets/syncthing-${hostname}-key.age";
      path = "${homeDirectory}/.local/state/syncthing/key.pem";
      mode = "0600";
    };

    syncthing-${hostname}-cert = {
      file = "${homeDirectory}/.nix-config/secrets/syncthing-${hostname}-cert.age";
      path = "${homeDirectory}/.local/state/syncthing/cert.pem";
      mode = "0600";
    };
  };
}
