_: {
  services.redshift = {
    enable = true;
    provider = "manual";
    latitude = "-22.90";
    longitude = "-47.06";
    temperature = {
      day = 3700;
      night = 3000;
    };
    settings.redshift = {
      brightness-day = "1.0";
      transition = "1";
      gamut = "1.0";
    };
  };
}
