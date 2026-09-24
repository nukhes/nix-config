_:

{
  nixos.modules.hackbook = { pkgs, ... }: {
    boot = {
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

      extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
      kernelPackages = lib.mkForce pkgs.linuxPackages_6_18;
      kernelModules = [ "msr" ];
      kernelParams = [
        "pci=noaer"
        "pcie_aspm=off"
        "acpi_osi=!Darwin"
        "mem_sleep_default=deep"
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

    time.timeZone = "America/Sao_Paulo";
    i18n = {
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = {
        LC_ADDRESS = "pt_BR.UTF-8";
        LC_IDENTIFICATION = "pt_BR.UTF-8";
        LC_MEASUREMENT = "pt_BR.UTF-8";
        LC_MONETARY = "pt_BR.UTF-8";
        LC_NAME = "pt_BR.UTF-8";
        LC_NUMERIC = "pt_BR.UTF-8";
        LC_PAPER = "pt_BR.UTF-8";
        LC_TELEPHONE = "pt_BR.UTF-8";
        LC_TIME = "pt_BR.UTF-8";
      };
    };
  };
}
