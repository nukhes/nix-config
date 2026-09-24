_:
let
  secrets = ../../secrets;
in
{
  nixos.modules.common = { pkgs, config, ... }: {
    age.secrets.tailscale-authkey = {
      file = "${secrets}/tailscale-authkey.age";
      owner = "root";
      group = "root";
    };

    virtualisation.docker.enable = true;

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

    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      description = "Polkit GNOME Authentication Agent";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };
}
