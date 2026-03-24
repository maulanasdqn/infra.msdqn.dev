{ pkgs, ... }:

{
  home.stateVersion = "24.05";

  programs.git = {
    enable = true;
    settings = {
      user.name = "maulanasdqn";
      user.email = "maulanasdqn@gmail.com";
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
    };
  };

  programs.zsh = {
    enable = true;
    shellAliases = {
      ls = "eza";
      ll = "eza -la";
      grep = "rg";
    };
  };

  programs.starship.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
  };
}
