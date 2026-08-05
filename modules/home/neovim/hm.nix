{
  pkgs,
  nixvim,
  ...
}:
{

  imports = [
    nixvim.homeModules.nixvim
    ./options.nix
    ./keymaps.nix
    ./plugins
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    version.enableNixpkgsReleaseCheck = false;

    nixpkgs.useGlobalPackages = true;

    extraPackages = with pkgs; [
      ripgrep
      fd
      prettierd
      stylua
      nixfmt
      eslint_d
    ];
  };
}
