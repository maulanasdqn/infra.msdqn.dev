{
  config,
  pkgs,
  nixvim,
  nixpkgs,
  claude-code,
  ...
}:

{
  imports = [

    ../default.nix
  ];

  user.shell = "${pkgs.zsh}/bin/zsh";

  nix.registry.nixpkgs.flake = nixpkgs;
  nix.nixPath = [ "nixpkgs=${nixpkgs}" ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit nixvim claude-code;
      enableLaravel = false;
    };
    config = {
      imports = [
        ../../../modules/home/zsh/hm.nix
        ../../../modules/home/starship/hm.nix
        ../../../modules/home/neovim/hm.nix
        ../../../modules/home/packages/cli.nix
      ];
      home.stateVersion = "24.05";
    };
  };
}
