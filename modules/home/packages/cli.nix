{
  pkgs,
  lib,
  claude-code ? null,
  ...
}:
{

  home.packages =
    (lib.optional (claude-code != null) claude-code.packages.${pkgs.system}.default)
    ++ (with pkgs; [

      eza
      bat
      fzf
      zoxide
      ripgrep
      fd
      jq
      yq

      tmux

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

      httpie
      xh

      p7zip
      unrar

      imagemagick
      ffmpeg
    ]);
}
