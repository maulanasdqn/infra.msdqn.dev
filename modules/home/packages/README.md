# Packages

| File | Scope |
|---|---|
| `cli.nix` | Shared CLI toolset, no GUI |
| `nixos.nix` | GUI / desktop-only apps |
| `darwin.nix` | macOS-only packages and session variables |

`cli.nix` is imported both by the workstation home config **and** directly by
nix-on-droid (`honor`), so phone and desktop get the same command-line tools.
Keep it free of anything that needs a display server or compiles heavy native
code — see `../neovim/README.md` for why mobile is sensitive to that.

`nixos.nix` is workstation-specific and pulls in the shared CLI set alongside
the desktop applications.

## Browsers

Two are installed: Helium (packaged locally in `../../../pkgs/helium-browser`)
and Google Chrome. Helium stays the **default** — `../nixos.nix` sets both
`BROWSER` and every `xdg.mimeApps` http/html handler to `helium.desktop`, so a
link clicked from another app opens Helium regardless of what else is
installed. Chrome is there to be launched deliberately.

To make Chrome the default instead, change those handlers to
`google-chrome.desktop` in `../nixos.nix`; installing it here is not enough on
its own.

Chrome is unfree. That builds only because `profiles/base.nix` sets
`nixpkgs.config.allowUnfree = true` for the whole workstation profile.

## `bear` on darwin

`darwin.nix` overrides nixpkgs' `bear` (4.2.3, nixpkgs 2026-10-16) in two ways.
Without them it does not build on macOS:

- **`postInstall`**: the upstream recipe runs `mv $out/lib/libexec.so`, which is
  the Linux filename. On macOS the preload library is `libexec.dylib`, so the
  install step fails. The override swaps in
  `stdenv.hostPlatform.extensions.sharedLibrary`.
- **`doCheck = false`**: three integration tests fail inside the macOS Nix
  sandbox: `forwards_the_exact_signal_received`,
  `signal_tears_down_build_process_tree` and
  `semantic_print_compilers_does_not_block_on_stdin`. They depend on signals and
  timing, which the sandbox breaks. The unit tests pass.

Remove the override once nixpkgs' `bear` builds on darwin as-is.
