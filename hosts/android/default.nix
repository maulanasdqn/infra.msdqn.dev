{
  config,
  pkgs,
  ...
}:

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
    ncurses # clear, tput, terminfo (needed by zsh/starship/TUIs)
    coreutils
  ];

  environment.etcBackupExtension = ".bak";

  # NOTE: a previous `fixNixEnvPty` activation hack wrapped nix-env with
  # `</dev/null`, which made the user-environment build fail with
  # "unexpected EOF reading a line" on first switch. Plain nix-on-droid
  # builds the user-environment fine (the "getting pseudoterminal
  # attributes: Permission denied" line is a harmless proot warning), so the
  # hack was removed.

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  time.timeZone = "Asia/Jakarta";

  system.stateVersion = "24.05";
}
