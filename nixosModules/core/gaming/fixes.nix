{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "p4g-fix" ''
      # export PIPEWIRE_LATENCY="1024/48000"
      export PROTON_USE_WINED3D=1
      exec gamemoderun "$@"
    '')
  ];
}
