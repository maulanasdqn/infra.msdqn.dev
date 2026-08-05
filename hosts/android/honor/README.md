# honor — HONOR X9c (BRP-NX1)

nix-on-droid host. Bootloader is **permanently locked**, so no custom ROM.

Imports the shared nix-on-droid base from `../default.nix`.

## Shell and NIX_PATH

zsh is the login shell.

`nixpkgs` is made to resolve for both flakes and legacy commands, pinned to the
same 25.11 nixpkgs the host is built from, so these both work:

```sh
nix shell nixpkgs#fastfetch   # flakes
nix-shell -p fastfetch        # needs <nixpkgs> in NIX_PATH
```

## Why 25.11 and not unstable

This host rides the **25.11 release** for `nixpkgs`, `home-manager` and
`nixvim`, for two reasons:

1. It predates the glibc 2.42 / nix 2.31.3 change that broke nix-on-droid proot
   builds (nix-on-droid #495).
2. Its aarch64 binaries — vim plugins, treesitter grammars, LSPs — are fully
   cached by Hydra, so the phone substitutes them instead of compiling
   on-device.

nixvim `main` pulls neovim 0.12 (glibc 2.42), which **freezes at TUI startup**
under proot. home-manager `master` likewise requires nixpkgs-unstable internals
that 25.11 lacks. Both are pinned to stable inputs in the flake for this host
only.

## Debugging from the Mac

Reachable over `adb` and ssh from the workstation for interactive debugging.
