# Homebrew

nix-darwin's Homebrew integration, for packages that cannot come from nixpkgs.

## `cleanup` is gated

`"zap"` removes unmanaged Homebrew packages **and their data**. That is fine on
the single-owner MacBook and destructive on the shared Mac mini, where it would
wipe the other account's formulae.

The shared machine uses `"none"`, which never touches packages this config does
not declare. The switch follows `enableAggressiveTweaks` — see
`../README.md`.

## Why anything is here at all

**xcodegen** comes from Homebrew rather than nixpkgs. Version 2.45+ requires
Swift 6, but nixpkgs' Swift toolchain is still 5.10.1 (even on master), so
nixpkgs can only build xcodegen 2.44.1. Homebrew ships the current release.

Revisit if nixpkgs' Swift catches up.
