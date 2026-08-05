# Neovim

| File | Role |
|---|---|
| `hm.nix` | Reusable config (editor + LSP). Mobile-safe. |
| `default.nix` | NixOS/Darwin wrapper — mounts `hm.nix`, adds desktop-only extras |
| `plugins/` | Plugin set |

`hm.nix` is imported directly by nix-on-droid (`honor`) as a single-user
home-manager module. `default.nix` is used on desktops and additionally pulls in
**stynx** (a Rust CLI built from source) and the Claude Code integration —
deliberately kept out of the shared set so the phone stays lean.

## Build against the host's `pkgs`

Nixvim is given the host's `pkgs` rather than importing its own Nixpkgs
instance. Without this, Nixvim constructs a second instance from its
`inputs.nixpkgs` — which our flake `follows`, so it lands on the same revision
anyway, just evaluated twice and **without** `allowUnfree` or our overlays. It
also settles the follows-vs-pin warning.

## Mobile constraints

`honor` runs under proot on nix-on-droid, which makes two things matter:

- **neovim 0.12 freezes at TUI startup** under proot (nix-on-droid #495/#539),
  which is why the flake pins a stable nixvim for that host.
- **treesitter must not compile at runtime.** `plugins/treesitter.nix` sets no
  `ensure_installed`: with `nixGrammars` every parser ships via Nix. A runtime
  list makes nvim-treesitter git-clone and compile parsers at startup — minutes
  of blocked first draw under proot — and `mdx`/`swift` can never install at all
  (no parser available / needs the tree-sitter CLI).

## plugins/

`default.nix` holds the shared set (editor UX + LSP). **stynx is intentionally
absent** — it compiles a Rust CLI from source, so it is added only by the
desktop wrapper and skipped on mobile.

`stynx.nix` is the shared source for both the editor plugin and the `stynx` CLI
it drives: the binary is the workspace member `stynx-code`, the plugin lives in
the repo's `stynx-code-nvim/` subdir, and the module puts `stynx` on Neovim's
PATH so the plugin's job runner can find it.
