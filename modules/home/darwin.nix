{
  username,
  enableLaravel ? false,
  enableRust ? false,
  enableVolta ? false,
  enableGolang ? false,
  sshKeys ? [ ],
  lib,
  ...
}:
{
  imports = [
    ./packages/darwin.nix
    ./git
    ./starship
    ./zsh
    ./neovim

    ./tmux
    ./docker
    ./ssh
    ./sops
    ./ghostty
    ./services
    ./wallpaper
    ./laravel
  ];

  nixpkgs.config.allowUnfree = true;
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.users.${username}.home.stateVersion = "24.11";
}
