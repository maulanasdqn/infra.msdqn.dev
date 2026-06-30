{ ... }:
{
  # Shared plugin set (editor UX + LSP). stynx is intentionally NOT here: it
  # compiles a Rust CLI from source, so it's added only by the desktop wrapper
  # (neovim/default.nix) and skipped on mobile (nix-on-droid imports ./hm.nix
  # directly).
  imports = [
    ./colorscheme.nix
    ./treesitter.nix
    ./telescope.nix
    ./cmp.nix
    ./ui.nix
    ./claudecode.nix
    ./lsp.nix
    ./formatting.nix
  ];
}
