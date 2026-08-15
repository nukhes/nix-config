{ pkgs, ... }:
{
  boot = {
    kernelModules = [ "msr" ];
    kernelParams = [
      "acpi_osi=!Darwin"
      "mem_sleep_default=deep"
    ];
  };

  environment.systemPackages = with pkgs; [
    brightnessctl
    powertop
  ];

  hardware.system76.power-daemon.enable = false;

  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

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

    mbpfan = {
      enable = true;
      settings = {
        general.polling_interval = 5;
        info = {
          min_fan_speed = 2000;
          max_fan_speed = 6200;
          low_temp = 55;
          high_temp = 65;
          max_temp = 75;
        };
      };
    };
  };

  systemd.services.disable-prochot = {
    description = "Disable BD_PROCHOT bypass to fix CPU throttling lock and apply PowerTop";
    after = [ "systemd-modules-load.service" ];
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [
      msr-tools
      powertop
    ];
    script = ''
      powertop --auto-tune
      wrmsr -a 0x1FC 0x4005a
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
}
