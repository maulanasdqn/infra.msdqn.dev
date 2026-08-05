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

## `homebrew.taps` must mirror `nix-homebrew.taps`

`taps = builtins.attrNames config.nix-homebrew.taps` is load-bearing, not
decoration.

nix-darwin generates a Brewfile and, when `onActivation.cleanup` is `"zap"`,
runs `brew bundle cleanup`, which removes anything **not** listed in it —
including taps. Leave `homebrew.taps` empty and the Brewfile has no `# Taps`
section, so every activation tries to untap `homebrew/cask` and
`homebrew/core`, and Homebrew refuses:

```
Error: Refusing to untap homebrew/cask because it contains the following
installed formulae or casks: discord, figma, slack, ...
```

That error is emitted during `Homebrew bundle...`, and it is *not* caused by
`autoMigrate`. Activation continues past it, so it is cosmetic — but it means
bundle cleanup is fighting nix-homebrew on every rebuild.

## The taps are already Nix-pinned

With `mutableTaps = false`, nix-homebrew replaces the tap directories with
read-only copies of the flake inputs, on the `/nix` volume:

```
dr-xr-xr-x root  /opt/homebrew/Library/Taps/homebrew/homebrew-cask
```

Their contents are byte-identical to the `homebrew-cask` / `homebrew-core`
inputs, and writes are refused. So cask definitions **are** version-pinned and
`brew update` cannot move them. Do not conclude from the untap error that taps
are mutable — check `df` on the tap directory instead.

Because of this, `brew untap --force` fails with `Permission denied` rather than
succeeding, which is the store protecting itself.

## cleanup = "zap" means declared and installed must match

On a machine with `enableAggressiveTweaks` (so `cleanup = "zap"`), anything
installed but not declared in `casks`/`brews` is removed **with its data** on
activation. Keep the two in sync; drift is a package waiting to be deleted.
