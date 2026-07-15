{
  config,
  pkgs,
  ...
}:
{
  age.secrets.gemini-p052 = {
    file = ../../../secrets/gemini-p052.age;
    path = "${config.home.homeDirectory}/.config/api-keys/gemini-p052";
    mode = "0600";
  };
}
