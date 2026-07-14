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
    # Shared nix-on-droid base (packages, nix-env shim, timezone, stateVersion)
    ../default.nix
  ];

  # Use zsh as the login shell.
  user.shell = "${pkgs.zsh}/bin/zsh";

  # Make `nixpkgs` resolve for both flakes and legacy commands, pinned to the
  # same 25.11 nixpkgs honor is built from:
  #   nix shell nixpkgs#fastfetch   (flakes)
  #   nix-shell -p fastfetch        (needs <nixpkgs> in NIX_PATH)
  nix.registry.nixpkgs.flake = nixpkgs;
  nix.nixPath = [ "nixpkgs=${nixpkgs}" ];

  # Reuse the same home-manager modules as the NixOS/Darwin hosts (zsh +
  # starship + neovim/nixvim) via their plain home-manager ./hm.nix entrypoints.
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
