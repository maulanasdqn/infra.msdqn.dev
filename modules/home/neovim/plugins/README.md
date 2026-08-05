# Neovim plugins

`default.nix` is the shared plugin set (editor UX + LSP), safe on mobile.

**stynx is intentionally not here.** It compiles a Rust CLI from source, so it
is added only by the desktop wrapper (`../default.nix`) and skipped on
nix-on-droid, which imports `../hm.nix` directly.

## stynx.nix

Shared source for both halves of stynx:

- the `stynx` binary — workspace member `stynx-code`, which the plugin shells
  out to
- the Neovim plugin — lives in the repo's `stynx-code-nvim/` subdir

The module puts `stynx` on Neovim's PATH so the plugin's job runner can find it.

## treesitter.nix

**No `ensure_installed`.** With `nixGrammars`, every parser ships via Nix.

A runtime list makes nvim-treesitter git-clone and compile parsers at startup.
That blocks the first draw for minutes under proot on nix-on-droid, and `mdx` /
`swift` can never install at all — no parser available, and it needs the
tree-sitter CLI.
