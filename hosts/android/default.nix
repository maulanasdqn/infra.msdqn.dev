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
    openssh
    zsh
    starship
    ncurses
    coreutils
  ];

  environment.etcBackupExtension = ".bak";

  terminal.font = "${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts/JetBrainsMono/JetBrainsMonoNerdFontMono-Regular.ttf";

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  time.timeZone = "Asia/Jakarta";

  system.stateVersion = "24.05";
}
