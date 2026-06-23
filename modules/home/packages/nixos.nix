{
  pkgs,
  username,
  claude-code,
  claude-desktop,
  ...
}:
{
  home-manager.users.${username}.home = {
    packages = with pkgs; [
      claude-code.packages.${pkgs.system}.default
      claude-desktop.packages.${pkgs.system}.claude-desktop-with-fhs
      (callPackage ../../../pkgs/helium-browser { })

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

      rustc
      cargo
      rustfmt
      clippy
      rust-analyzer
      gcc

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
      brightnessctl
      swayosd

      httpie
      xh

      p7zip
      unrar

      slack
      discord

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
      "$HOME/.cargo/bin"
    ];
  };
}
