{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./../../nixosModules/services
  ];

  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
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

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_6_18;
  services.fstrim.enable = true;

  users.users."user" = {
    isNormalUser = true;
    description = "user";
    extraGroups = ["networkmanager" "wheel" "video" "audio"];
    packages = with pkgs; [];
  };

  nix.settings.experimental-features = ["nix-command" "flakes"];
  nixpkgs.config.allowUnfree = true;

  networking.hostName = "hackbook";

  boot.kernelParams = [
    "i915.enable_fbc=1"
    "i915.enable_guc=3"
    "acpi_osi=Darwin"
    "acpi_mask_gpe=0x17"
    "pcie_aspm=force"
    "mem_sleep_default=deep"
  ];

  zramSwap = {
    enable = true;
    priority = 100;
    algorithm = "zstd";
    memoryPercent = 100;
  };

  networking.networkmanager.wifi.powersave = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # Broadcom Wifi Chip
  networking.wireless.enable = true;
  nixpkgs.config.permittedInsecurePackages = [
    "broadcom-sta-6.30.223.271-59-6.18.34"
  ];
  boot.kernelModules = ["wl"];
  boot.extraModulePackages = [config.boot.kernelPackages.broadcom_sta];
  boot.blacklistedKernelModules = ["b43" "bcma" "ssb" "brcmsmac"];
  # End Broadcom Wifi Chip

  system.stateVersion = "26.05";
}
