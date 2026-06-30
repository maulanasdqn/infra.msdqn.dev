{
  pkgs,
  nixvim,
  ...
}:
{
  # Reusable neovim config (editor + LSP). Imported by the NixOS/Darwin wrapper
  # (./default.nix, which also adds stynx) and directly by nix-on-droid/honor.
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
