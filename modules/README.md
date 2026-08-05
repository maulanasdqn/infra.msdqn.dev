# Modules

Reusable configuration, grouped by platform.

| Directory | Scope |
|---|---|
| `darwin/` | macOS (nix-darwin) |
| `nixos/` | NixOS hosts |
| `home/` | home-manager, shared across platforms |

Several `home/` modules use a two-file wrapper pattern so the same config works
under full NixOS/Darwin **and** standalone single-user home-manager on
nix-on-droid. See `home/README.md`.

## nix.nix — Determinate Nix (darwin only)

Imported only from `mkDarwinMachine` in `flake.nix`, so everything in it is
macOS-specific. It is *not* applied everywhere.

`nix.enable = false` hands Nix management to **Determinate Nix**. The important
consequence is that **nix-darwin's `nix.gc.*` and `nix.optimise.*` options do
nothing** — they are guarded by `nix.enable`. Store maintenance must therefore
be expressed as raw settings in `determinateNix.customSettings`, or as a launchd
job. Do not "fix" missing GC by adding `nix.gc.automatic`; it will silently have
no effect.

### Store maintenance

Determinate's defaults leave a Mac with no maintenance at all —
`auto-optimise-store = false`, `min-free = 0`, `max-free` effectively infinite.
Left alone the store grows without bound and never deduplicates. This one
reached **82 GB with 54,000 dead paths and 27 system generations**, the oldest
ten still pinning nixpkgs `26.05` and four more pinning `26.11.d5bd9cd`.

| Setting | Value | Effect |
|---|---|---|
| `auto-optimise-store` | `true` | Hardlinks identical files after every build |
| `min-free` | 10 GiB | Below this free space, Nix garbage-collects mid-build |
| `max-free` | 50 GiB | Collection stops once this much is free |

`launchd.daemons.nix-gc` runs `nix-collect-garbage --delete-older-than 30d`
weekly (Sunday 04:00) at low IO priority and `Nice = 10`, so it never competes
with foreground work. Logs to `/var/log/nix-gc.log`.

Thirty days is deliberate: a month of rollback points, without generations
accumulating forever.

### Binary caches and trust

`extra-substituters` carries three caches beyond `cache.nixos.org`:

| Cache | Why |
|---|---|
| `msdqn.cachix.org` | Your own. `profiles/server.nix` has always used it; the Macs did not, so they rebuilt from source what the cache already had. |
| `devenv.cachix.org` | Every `templates/*/flake.nix` declares it. |
| `nix-on-droid.cachix.org` | aarch64 substitutes for the phone host. |

Public keys are copied from the authoritative places in this repo —
`profiles/server.nix` for msdqn, the templates for devenv. Do not retype a
cache key from memory; a wrong key does not error loudly, it just silently
fails signature checks and the machine builds from source instead.

**`trusted-users` must include the primary user.** With only `root` trusted, a
flake's own `extra-substituters` are silently ignored — so the devenv caches
declared in `templates/` never applied, and every clan invocation needed
`--option accept-flake-config true` to work around it. `nix store ping --json`
reports `trusted: false` when this is wrong.

Two things to know:

- The daemon reads `trusted-users` **at startup**. After changing it, restart
  with `sudo launchctl kickstart -k system/systems.determinate.nix-daemon`, or
  the setting appears in `nix config show` while still not taking effect.
- A trusted user can add substituters and insert store paths. On a single-owner
  Mac that is no escalation — they already have sudo. On the shared Mac mini
  only that machine's own primary user becomes trusted, not the second account.

`connect-timeout = 5` (down from 15) so an unreachable substituter fails over
quickly instead of stalling every fetch.

### Performance settings

`eval-cores = 0` plus the `parallel-eval` and `build-time-fetch-tree`
experimental features enable Determinate's parallel evaluator.
`download-buffer-size` is raised to 128 MiB because the default is small enough
to bottleneck substitution on a fast connection.

### direnv holds the store open

`.direnv` directories are GC roots — this repo alone had **88** of them pinning
old flake inputs, and they survive garbage collection by design. If a project is
finished, delete its `.direnv` before expecting its inputs to be collected.
