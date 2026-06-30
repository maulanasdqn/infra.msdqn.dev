{
  pkgs,
  lib,
  claude-code ? null,
  ...
}:
{
  # Shared CLI toolset (no GUI). Imported by the workstation home config and
  # directly by nix-on-droid/honor so both get the same command-line tools.
  home.packages =
    (lib.optional (claude-code != null) claude-code.packages.${pkgs.system}.default)
    ++ (with pkgs; [
      # modern coreutils / search
      eza
      bat
      fzf
      zoxide
      ripgrep
      fd
      jq
      yq

      # terminal multiplexer
      tmux

      # languages / runtimes
      nodejs_22
      pnpm
      bun
      go
      python3

      # rust
      rustc
      cargo
      rustfmt
      clippy
      rust-analyzer
      gcc

      # containers (CLI)
      docker-compose
      lazydocker

      # git
      lazygit
      gh
      delta

      # system / monitoring
      ncdu
      duf
      procs
      bottom
      htop
      tldr

      # http
      httpie
      xh

      # archives
      p7zip
      unrar

      # media
      imagemagick
      ffmpeg
    ]);
}
