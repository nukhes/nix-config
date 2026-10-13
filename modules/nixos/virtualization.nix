_:

{
  nixos.modules.desktop = { pkgs, ... }: {
    virtualisation = {
      virtualbox.host.enable = true;
      docker.enable = true;
      libvirtd = {
        enable = true;
        qemu = {
          swtpm.enable = true;
        };
      };
      spiceUSBRedirection.enable = true;
    };

    users.groups.libvirtd.members = [ "user" ];
    users.groups.kvm.members = [ "user" ];

    environment.systemPackages = with pkgs; [
      gnome-boxes
      dnsmasq
      phodav
    ];
  };
}
