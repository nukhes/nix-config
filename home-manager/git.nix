{ config, pkgs, ... }:

{
  programs.git.enable = true;
  programs.git.settings = {
    user.name = "Pedro Henrique";
    user.email = "79018158+nukhes@users.noreply.github.com";
    init.defaultBranch = "main";
    pull.rebase = false;
    rebase.autoStash = true;
    filter."lfs" = {
      clean = "git-lfs clean -- %f";
      smudge = "git-lfs smudge -- %f";
      process = "git-lfs filter-process";
      required = true;
    };
  };
}
