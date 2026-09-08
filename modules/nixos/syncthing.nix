{ config, lib, ... }:

let
  hostname = config.networking.hostName;

  # ── Device registry ──────────────────────────────────────────────
  # All devices in the Syncthing mesh, keyed by hostname.
  allDevices = {
    x99 = {
      id = "6XKO7MN-7XE4EDE-BVNJZO4-JGN4TJG-CCLSEBJ-3JNVY2B-PD3ZX6B-MTTQCAC";
    };
    hackbook = {
      id = "5MBTINO-KGSNPN4-RHH4CSA-7VNAOLF-RIIEYEF-5L3OFGP-AYBJVDF-EYNG2QX";
    };
  };

  # Only remote peers (exclude the local host from the device map)
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

    # ── Immutable state ────────────────────────────────────────────
    # Ensures Nix is the single source of truth: any changes made
    # through the WebUI will be reverted on the next rebuild.
    overrideDevices = true;
    overrideFolders = true;

    # ── Identity persistence via agenix ────────────────────────────
    # Uncomment the lines below and point them to your agenix secrets
    # to preserve the Device ID across reinstalls / reformats.
    #
    # 1. Back up the current cert/key:
    #      cp ~/.config/syncthing/cert.pem /path/to/secrets/syncthing-<host>-cert.pem
    #      cp ~/.config/syncthing/key.pem  /path/to/secrets/syncthing-<host>-key.pem
    #
    # 2. Encrypt with agenix and reference here:
    #      cert = config.age.secrets."syncthing-cert".path;
    #      key  = config.age.secrets."syncthing-key".path;

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

  # ── Firewall ─────────────────────────────────────────────────────
  # TCP 22000 — sync protocol
  # UDP 22000 — QUIC sync protocol
  # UDP 21027 — local discovery broadcasts
  networking.firewall = {
    allowedTCPPorts = [ 22000 ];
    allowedUDPPorts = [ 22000 21027 ];
  };
}
