{
  config,
  pkgs,
  ...
}:
{
  programs.khal = {
    enable = true;
    locale = {
      timeformat = "%H:%M";
      dateformat = "%d/%m/%Y";
      longdateformat = "%d/%m/%Y";
    };
    settings = {
      calendars = {
        unicamp = {
          path = "~/.ics/";
          type = "calendar";
        };
      };
      default = {
        default_calendar = "unicamp";
      };
    };
  };

  services.vdirsyncer = {
    enable = true;
    frequency = "30m";
  };

  age.secrets.vdirsyncer = {
    file = ../../secrets/vdirsyncer.age;
    path = "${config.home.homeDirectory}/.config/vdirsyncer/config";
    mode = "0600";
  };
}
