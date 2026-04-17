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
    ./neovim
    ./tmux
    ./ssh
  ];

  home-manager.users.${username} = {
    home = {
      username = username;
      homeDirectory = "/home/${username}";
      stateVersion = "25.05";

      packages = with pkgs; [
        eza
        bat
        fzf
        zoxide
        ripgrep
        fd
        jq
        yq

        nodejs_22
        pnpm
        bun
        go
        python3

        docker-compose
        lazydocker

        lazygit
        gh
        delta

        ncdu
        duf
        procs
        bottom
        htop
        tldr

        httpie
        xh

        p7zip
        unrar

        imagemagick
        ffmpeg
      ];

      sessionVariables = {
        EDITOR = "nvim";
        GOPATH = "$HOME/go";
      };

      sessionPath = [
        "$HOME/.local/bin"
        "$HOME/go/bin"
        "$HOME/.bun/bin"
      ];
    };

    programs.home-manager.enable = true;
  };
}
