{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    unrar
  ];
  nixpkgs.config.allowUnfree = true;
}
