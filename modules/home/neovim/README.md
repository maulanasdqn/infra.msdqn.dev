# Neovim

| File | Role |
|---|---|
| `hm.nix` | Reusable config (editor + LSP). Mobile-safe. |
| `default.nix` | NixOS/Darwin wrapper — mounts `hm.nix`, adds desktop-only extras |
| `plugins/` | Plugin set |

`hm.nix` is imported directly by nix-on-droid (`honor`) as a single-user
home-manager module. `default.nix` is used on desktops and additionally pulls in
the Claude Code integration — deliberately kept out of the shared set so the
phone stays lean.

## Build against the host's `pkgs`

Nixvim is given the host's `pkgs` rather than importing its own Nixpkgs
instance. Without this, Nixvim constructs a second instance from its
`inputs.nixpkgs` — which our flake `follows`, so it lands on the same revision
anyway, just evaluated twice and **without** `allowUnfree` or our overlays.
Nixvim warns about exactly that follows-vs-pin mismatch and asks for either the
follows to be dropped or `nixpkgs.source` to be pinned; reusing the host pkgs
settles it without a duplicate instance.

This is also what keeps `honor` correct. That host builds `pkgs` from
`nixpkgs-stable`, so Nixvim inherits **neovim 0.11 from 25.11** rather than
0.12/glibc 2.42, which freezes at TUI startup under proot. The `nixvim-stable`
input stays for the module set; this option is what makes the *package* follow
the host.

## Mobile constraints

`honor` runs under proot on nix-on-droid, which makes two things matter:

- **neovim 0.12 freezes at TUI startup** under proot (nix-on-droid #495/#539) —
  see the pkgs note above.
- **treesitter must not compile at runtime.** `plugins/treesitter.nix` sets no
  `ensure_installed`: with `nixGrammars` every parser ships via Nix. A runtime
  list makes nvim-treesitter git-clone and compile parsers at startup — minutes
  of blocked first draw under proot — and `mdx`/`swift` can never install at all
  (no parser available / needs the tree-sitter CLI).
