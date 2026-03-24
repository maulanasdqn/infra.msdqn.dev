{ config, lib, pkgs, ... }:

{
  environment.packages = with pkgs; [
    git
    curl
    wget
    jq
    ripgrep
    fd
    fzf
    bat
    htop
    tmux
    openssh
    zsh
    starship
  ];

  environment.etcBackupExtension = ".bak";

  # Bypass nix-env/nix-profile entirely — both trigger user-environment.drv
  # which calls tcgetattr() → proot returns EACCES → PTY permission denied error.
  # Direct symlink to the store path avoids the build entirely.
  build.activation.installPackages = lib.mkForce ''
    $DRY_RUN_CMD ln -sfn ${config.environment.path} ${config.user.home}/.nix-profile
  '';

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  time.timeZone = "Asia/Jakarta";

  system.stateVersion = "24.05";
}
