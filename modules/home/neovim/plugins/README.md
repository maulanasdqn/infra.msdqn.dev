# Neovim plugins

`default.nix` is the shared plugin set (editor UX + LSP), safe on mobile.

## lsp.nix — sourcekit-lsp is Darwin-only

The Swift/ObjC server's `cmd` points at the Xcode toolchain's `sourcekit-lsp`,
which only exists on macOS. It is gated behind Darwin because on the Linux hosts
(vivobook, pc, wsl, honor) the server would fail to spawn on every swift or objc
buffer.

## treesitter.nix — no `ensure_installed`

With `nixGrammars`, every parser ships via Nix.

A runtime list makes nvim-treesitter git-clone and compile parsers at startup.
That blocks the first draw for minutes under proot on nix-on-droid, and `mdx` /
`swift` can never install at all — no parser available, and it needs the
tree-sitter CLI.
