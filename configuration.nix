{ config, pkgs, agenixModule, ... }:

{
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

  imports = [
    agenixModule
  ];
  
  networking.networkmanager.enable = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_6_6;

  services.xserver.xkb = {
    layout = "us";
    variant = "altgr-intl";
  };

  services.xserver = {
    enable = true;
    autoRepeatDelay = 200;
    autoRepeatInterval = 35;
    windowManager.i3.enable = true;
  };

  services.displayManager.ly.enable = true;

  users.users."user" = {
    isNormalUser = true;
    description = "user";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
    packages = with pkgs; [];
  };

  nixpkgs.config.allowUnfree = true;

  programs.firefox.enable = true;

  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-vcs-plugin
    ];
  };

  environment.systemPackages = with pkgs; [
    wget
    git
    xarchiver
    unzip
    p7zip
    papirus-icon-theme
    fzf
    dust
    eza
    zoxide
    calibre
    xournalpp
    gparted
    rclone
    rsync
    lazygit
    gh
    tectonic
    anki-bin
    brightnessctl
    maim
    xclip
    picom
    sxiv
    bat
    asdf-vm
    cargo
    gcc
    rustc
    lua
    luarocks
    nil
    nixfmt
    ouch
  ];

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.iosevka
    ];
    fontconfig = {
      defaultFonts = {
        serif = [ "Iosevka Nerd Font" ];
        sansSerif = [ "Iosevka Nerd Font" ];
        monospace = [ "Iosevka Nerd Font" ];
      };
    };
  };
  environment.variables = {
    GTK_THEME = "Adwaita:dark";
    QT_QPA_PLATFORMTHEME = "gtk3";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  security.polkit.enable = true;
  security.rtkit.enable = true;
  services.udisks2.enable = true;
  programs.dconf.enable = true;
  services.openssh.enable = true;

  # Agenix Setup
  age.identityPaths = [ 
    "/etc/ssh/ssh_host_ed25519_key" 
  ];
  age.secrets.eduroam = {
    file = ./secrets/eduroam.age;
    path = "/etc/NetworkManager/system-connections/eduroam.nmconnection";
    mode = "0600";
    owner = "root";
    group = "root";
  };
  age.secrets.rclone = {
    file = ./secrets/rclone.age;
    path = "/home/user/.config/rclone/rclone.conf";
    mode = "0600";
    owner = "user";
    group = "users";
  };
  # End Agenix Setup

  system.stateVersion = "26.05";
}

