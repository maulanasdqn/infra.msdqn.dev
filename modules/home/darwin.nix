{
  username,
  enableLaravel ? false,
  enableRust ? false,
  enableVolta ? false,
  enableGolang ? false,
  sshKeys ? [ ],
  mac-app-util,
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
    ./kitty
    ./services
    ./wallpaper
    ./laravel
  ];

  nixpkgs.config.allowUnfree = true;
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.sharedModules = [ mac-app-util.homeManagerModules.default ];
  home-manager.users.${username}.home.stateVersion = "24.11";
}
