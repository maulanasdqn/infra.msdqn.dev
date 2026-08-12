{
  username,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./git
    ./starship
    ./zsh
    ./tmux
  ];

  home-manager.users.${username} = {
    home = {
      username = username;
      homeDirectory = if username == "root" then "/root" else "/home/${username}";
      stateVersion = "25.05";

      packages = with pkgs; [
        eza
        bat
        fzf
        zoxide
        ripgrep
        fd
        jq

        htop
        ncdu

        curl
        wget
      ];

      sessionVariables = {
        EDITOR = "nano";
      };

      sessionPath = [
        "$HOME/.local/bin"
      ];
    };

    programs.home-manager.enable = true;

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
    };
  };
}
