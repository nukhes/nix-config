{
  pkgs,
  lib,
  config,
  modules,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    "${modules}/nixos/common/"
    "${modules}/nixos/laptop.nix"
    "${modules}/nixos/broadcom.nix"
  ];

  networking = {
    hostName = "hackbook";
    networkmanager = {
      enable = true;
      wifi.powersave = false;
    };
  };

  boot = {
    extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
    kernelPackages = lib.mkForce pkgs.linuxPackages_6_18;
    kernelModules = [ "msr" ];
    kernelParams = [
      "pci=noaer"
      "pcie_aspm=off"
      "acpi_osi=!Darwin"
      "mem_sleep_default=deep"
      # Cala a boca do kernel
      "quiet"
      "loglevel=0"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=0"
      "udev.log_priority=0"
      "vt.global_cursor_default=0"
    ];
    consoleLogLevel = 0;
    extraModprobeConfig = ''
      options wl use_msi=0
    '';
  };

  hardware.enableRedistributableFirmware = true;

  environment.systemPackages = [ pkgs.moonlight-qt ];

  services.mbpfan = {
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

  systemd.services.disable-prochot = {
    description = "Disable BD_PROCHOT and apply PowerTop auto-tune";
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

  zramSwap = {
    enable = true;
    priority = 100;
    algorithm = "zstd";
    memoryPercent = 80;
  };

  nix.settings = {
    max-jobs = 1;
    cores = 1;
  };

  # ── Cala a boca de tudo ──
  # Desativa audit completamente
  security.audit.enable = false;
  security.auditd.enable = false;

  # Journald: só volatile, mínimo possível, sem persistência
  services.journald.extraConfig = ''
    Storage=volatile
    RuntimeMaxUse=1M
    RuntimeMaxFileSize=128K
    MaxLevelStore=crit
    MaxLevelSyslog=crit
    MaxLevelKMsg=crit
    MaxLevelConsole=crit
    MaxLevelWall=crit
    Compress=no
    ForwardToSyslog=no
    ForwardToKMsg=no
    ForwardToConsole=no
    ForwardToWall=no
  '';

  # Desativa coredumps
  systemd.coredump.extraConfig = ''
    Storage=none
    ProcessSizeMax=0
  '';

  system.stateVersion = "26.05";
}
