{
  config,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    lazygit
    gh
  ];
  programs.git = {
    enable = true;
    lfs.enable = true;
  };

  programs.git.settings = {
    user.name = "Pedro Henrique";
    user.email = "79018158+nukhes@users.noreply.github.com";
    init.defaultBranch = "main";
    pull.rebase = false;
    rebase.autoStash = true;
  };
}
