_:

{
  nixos.modules.desktop = { pkgs, ... }: {
    virtualisation = {
      host.enable = true;
      docker.enable = true;
      libvirtd = {
        enable = true;
        qemu = {
          swtpm.enable = true;
          ovmf.packages = [ pkgs.OVMFFull.fd ];
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
