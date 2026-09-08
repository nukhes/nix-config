{ secrets, config, ... }: {
  age.secrets.tailscale-authkey = {
    file = "${secrets}/tailscale-authkey.age";
    owner = "root";
    group = "root";
  };

  services = {
    openssh.enable = true;
    fstrim.enable = true;
    udisks2.enable = true;
    gvfs.enable = true;
    tumbler.enable = true;
    displayManager.ly.enable = true;
    tailscale = {
      enable = true;
      authKeyFile = config.age.secrets.tailscale-authkey.path;
    };
    usbmuxd.enable = true;
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };
    xserver = {
      enable = true;
      autoRepeatDelay = 200;
      autoRepeatInterval = 35;
      xkb = {
        layout = "us";
        variant = "intl";
      };
      windowManager.i3.enable = true;
    };
    earlyoom = {
      enable = true;
      freeMemThreshold = 5;
      freeSwapThreshold = 5;
    };
  };
}
