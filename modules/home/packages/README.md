# Packages

| File | Scope |
|---|---|
| `cli.nix` | Shared CLI toolset, no GUI |
| `nixos.nix` | GUI / desktop-only apps |

`cli.nix` is imported both by the workstation home config **and** directly by
nix-on-droid (`honor`), so phone and desktop get the same command-line tools.
Keep it free of anything that needs a display server or compiles heavy native
code — see `../neovim/README.md` for why mobile is sensitive to that.

`nixos.nix` is workstation-specific and pulls in the shared CLI set alongside
the desktop applications.
