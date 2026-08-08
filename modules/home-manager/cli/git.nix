{ pkgs, ... }:
{
  home.packages = with pkgs; [
    lazygit
    gh
    github-desktop
  ];

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user.name = "Pedro Henrique";
      user.email = "79018158+nukhes@users.noreply.github.com";
      init.defaultBranch = "main";
      pull.rebase = false;
      rebase.autoStash = true;
    };
  };

  home.shellAliases = {
    git = "git";
    gs = "git status";
    gss = "git status -s";
    ga = "git add";
    gaa = "git add --all";
    gc = "git commit";
    gcm = "git commit -m";
    gca = "git commit --amend";
    gp = "git push";
    gpl = "git pull";
    gpo = "git push origin HEAD";
    gl = "git log --oneline --graph --decorate --all";
    gd = "git diff";
    gds = "git diff --staged";
    gb = "git branch";
    gba = "git branch -a";
    gco = "git checkout";
    gcb = "git checkout -b";
    gcp = "git cherry-pick";
    gr = "git restore";
  };
}
