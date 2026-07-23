{
  config,
  pkgs,
  ...
}:
{
  programs.bash = {
    enable = true;
    shellAliases = {
      noise = "play -n synth brownnoise mix synth sine amod 0.1";
    };
  };
}
