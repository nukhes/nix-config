_:
{
  nixos.modules.laptop = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      brightnessctl
      powertop
    ];

    hardware.system76.power-daemon.enable = false;

    powerManagement.enable = true;

    services = {
      power-profiles-daemon.enable = false;

      tlp = {
        enable = true;
        settings = {
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
          CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        };
      };
    };
  };
}
