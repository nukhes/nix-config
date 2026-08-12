_: {
  services.openssh.enable = true;
  security.rtkit.enable = true;
  services.fstrim.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;
  services.displayManager.ly.enable = true;
  services.tailscale.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

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
}
