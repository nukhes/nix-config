_: {
  users = {
    users.user = {
      isNormalUser = true;
      group = "user";
      extraGroups = [
        "networkmanager"
        "wheel"
        "video"
        "audio"
        "docker"
      ];
    };
    groups.user = { };
  };
}
