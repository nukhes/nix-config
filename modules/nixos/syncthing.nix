_:
let
  secrets = ../../secrets;
in
{
  nixos.modules.common =
    {
      config,
      lib,
      ...
    }:

    let
      hostname = config.networking.hostName;

      allDevices = {
        x99.id = "IEU2MPE-TFUEDDX-MEXDGKN-SDRFKUQ-LTHGOIM-TK5N7UF-N7QNTNJ-INJJCAY";
        x200.id = "GNYGHFA-UN7D6NJ-M7QHP2P-J727PSP-QF4DY3D-UQ7INRH-XODZDXQ-QFO2OQN";
        hackbook.id = "NUOKH6I-6LV6VLV-4KKWBAU-GXZHPAJ-JSXPG6W-ZC76LPN-NXCKHRO-6SWEZQT";
        tab-s10-lite.id = "DFYNYPB-2AYM7ZA-PWVE3MQ-WR7AZDR-ZQB4OYE-L4WORQJ-VV3ZCLZ-L6KU3Q6";
        SM-A576B.id = "ELI2YQV-5JKNJPV-DHLGZKG-WIY7KO6-2Y5OGHC-4QS7T5V-YUXXQTD-LPCZ7QO";
      };

      isValidDevice = lib.hasAttr hostname allDevices;
      hasSecrets =
        builtins.pathExists "${secrets}/syncthing/${hostname}/key.age"
        && builtins.pathExists "${secrets}/syncthing/${hostname}/cert.age";
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
            vault = {
              path = "/home/user/vault";
              devices = remoteDeviceNames;
            };
          };
        };
      };

      age.secrets = {
        "syncthing-${hostname}-key" = {
          file = "${secrets}/syncthing/${hostname}/key.age";
          path = "/home/user/.local/state/syncthing/key.pem";
          mode = "0600";
        };
        "syncthing-${hostname}-cert" = {
          file = "${secrets}/syncthing/${hostname}/cert.age";
          path = "/home/user/.local/state/syncthing/cert.pem";
          mode = "0600";
        };
      };
    };
}
