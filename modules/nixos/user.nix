_: {
  users.users."user" = {
    isNormalUser = true;
    isSystemUser = false;
    group = "user";
    home = "/home/user";
    description = "user";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
    ];
  };

  users.groups."user" = { };
}
