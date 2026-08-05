# CLAUDE.md

Working rules for this repository.

## No comments in Nix files

**Nix files contain no comments. Documentation lives in `README.md`, one per
folder.**

Do not add `#` line comments or `/* */` block comments to any `.nix` file. When
something needs explaining — a magic number, a workaround, a non-obvious
ordering, a deliberate omission — write it in the `README.md` of the directory
that file lives in.

Every directory containing `.nix` files has a `README.md`. If you add a new
directory, add its README too. If you change behaviour that an existing README
describes, update the README in the same commit.

### What still belongs in a `.nix` file

Only text that is **not a Nix comment**:

- `#` inside a string is data, not a comment. Hex colours (`"#1f1d2e"`),
  shebangs inside `printf`, and comments within embedded shell, nginx or
  systemd config in `''...''` blocks are all part of the value and must be left
  alone.
- Nix expressions themselves — use clear attribute names instead of a comment.

### Removing comments safely

Never strip comments with a regex. `#` appears constantly inside strings in this
repo, and `sed 's/#.*//'` will silently corrupt colour values, shebangs and
embedded scripts.

Parse Nix properly (track `"..."`, `''...''` and `${...}` interpolation), then
**prove** the change is inert by comparing derivation hashes before and after:

```sh
nix eval --raw ".#nixosConfigurations.hostinger.config.system.build.toplevel.drvPath"
nix eval --raw ".#darwinConfigurations.$(scutil --get LocalHostName).system.drvPath"
```

Identical hashes mean zero semantic change. If a hash moves, revert rather than
ship it.

## Deploying

The VPS builds its own system — a Mac cannot cross-compile to `x86_64-linux`:

```sh
clan machines update hostinger \
  --build-host root@72.62.125.38 \
  --target-host root@72.62.125.38
```

Every switch stops all containers, including Postgres, and each app waits on its
`*-migrate.service`. Budget **~2 minutes of 502s** on all four KYA apps per
deploy, and say so before deploying during working hours.

## Verify before claiming

State outcomes as they are. If a check did not run, say so. Confirm a service is
healthy from outside (`curl` the public URL), not just that systemd reports
`active`.

Watch for space that looks freed but is not: a deleted file held open by a
running process keeps its blocks. Check `/proc/*/fd` for `(deleted)` handles
before reporting reclaimed disk.
