_: {
  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642;
    "fs.file-max" = 2097152;
  };

  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "524288";
    }
    {
      domain = "*";
      type = "hard";
      item = "nofile";
      value = "1048576";
    }
  ];
}
