{
  config,
  pkgs,
  ...
}:
{
  services.redshift = {
    enable = true;
    provider = "manual";
    latitude = "-22.90";
    longitude = "-47.06";
    temperature = {
      day = 5500;
      night = 3700;
    };
    settings = {
      redshift = {
        brightness-day = "1.0";
        transition = "1";
        gamut = "1.0";
      };
    };
  };
}
