{
  config,
  lib,
  secrets,
  ...
}:

let
  hostname = config.networking.hostName;

  allDevices = {
    x99.id = "IEU2MPE-TFUEDDX-MEXDGKN-SDRFKUQ-LTHGOIM-TK5N7UF-N7QNTNJ-INJJCAY";
    hackbook.id = "NUOKH6I-6LV6VLV-4KKWBAU-GXZHPAJ-JSXPG6W-ZC76LPN-NXCKHRO-6SWEZQT";
  };

  isValidDevice = lib.hasAttr hostname allDevices;
  hasSecrets =
    builtins.pathExists "${secrets}/syncthing-${hostname}-key.age"
    && builtins.pathExists "${secrets}/syncthing-${hostname}-cert.age";
  enableSyncthing = isValidDevice && hasSecrets;

  remoteDevices = lib.filterAttrs (name: _: name != hostname) allDevices;
  remoteDeviceNames = lib.attrNames remoteDevices;
in
lib.mkIf enableSyncthing {
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
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

  age.secrets = {
    "syncthing-${hostname}-key" = {
      file = "${secrets}/syncthing-${hostname}-key.age";
      path = "/home/user/.local/state/syncthing/key.pem";
      mode = "0600";
    };
    "syncthing-${hostname}-cert" = {
      file = "${secrets}/syncthing-${hostname}-cert.age";
      path = "/home/user/.local/state/syncthing/cert.pem";
      mode = "0600";
    };
  };
}
