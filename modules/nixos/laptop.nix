{
  pkgs,
  ...
}:
{
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      wifi.powersave = "off"; 
    };
  };

  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  hardware.system76.power-daemon.enable = false;
  services.power-profiles-daemon.enable = false;

  boot.kernelParams = [
    "acpi_osi=!Darwin"
    "mem_sleep_default=s2idle"
  ];

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

  boot.kernelModules = [ "msr" ];
  systemd.services.disable-prochot = {
    description = "Disable BD_PROCHOT bypass to fix CPU throttling lock";
    after = [ "systemd-modules-load.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.msr-tools ];
    script = ''
      # Write to all CPU cores (wrmsr -a)
      wrmsr -a 0x1FC 0x4005a
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
}
