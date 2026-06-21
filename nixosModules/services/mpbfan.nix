{ config, pkgs, ... }: {
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

  boot.kernelModules = [
    "applesmc"
    "coretemp"
  ];
}
