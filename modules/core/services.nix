{
  config,
  pkgs,
  ...
}:
{
  services.openssh.enable = true;
  security.polkit.enable = true;
  security.rtkit.enable = true;
  services.fstrim.enable = true;
  services.udisks2.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  networking.networkmanager.enable = true;
  networking.wireless.enable = true;

  services.displayManager.ly.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "intl";
  };

  services.xserver = {
    enable = true;
    autoRepeatDelay = 200;
    autoRepeatInterval = 35;
    windowManager.i3.enable = true;
  };

  services.gvfs.enable = true;
  services.tumbler.enable = true;

  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
  ];

  age.secrets.eduroam = {
    file = ../../secrets/eduroam.age;
    path = "/etc/NetworkManager/system-connections/eduroam.nmconnection";
    mode = "0600";
    owner = "root";
    group = "root";
    symlink = false;
  };
}
