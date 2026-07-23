{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [ tlp ];
  powerManagement.powertop.enable = true;
  services.power-profiles-daemon.enable = false;
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
    };
  };

  services.mbpfan = {
    enable = true;
    settings = {
      general = {
        polling_interval = 5;
      };
      info = {
        min_fan_speed = 2000;
        max_fan_speed = 6200;
        low_temp = 55;
        high_temp = 65;
        max_temp = 75;
      };
    };
  };
}
