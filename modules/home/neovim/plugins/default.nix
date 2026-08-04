{ ... }:
{
  # Shared plugin set (editor UX + LSP).
  imports = [
    ./colorscheme.nix
    ./treesitter.nix
    ./telescope.nix
    ./cmp.nix
    ./ui.nix
    ./lsp.nix
    ./formatting.nix
  ];
}
