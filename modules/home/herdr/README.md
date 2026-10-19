# herdr

Installs [Herdr](https://herdr.dev), a terminal workspace manager for AI coding
agents, from nixpkgs and writes `~/.config/herdr/config.toml`.

- Theme is `rose-pine`, matching tmux, Ghostty and nvim.
- Prefix is `Ctrl+a` and the bindings follow `../tmux`: `h/j/k/l` move between
  panes, `c` new tab, `n`/`p` next/previous tab, `1..9` jump to a tab, `z` zoom,
  `d` detach. Splits stay on Herdr's `v` (side by side) and `-` (stacked).
- `version_check` is off because Nix pins the version; `herdr update` would
  fight the store path. Bump it with `nix flake update` instead.
- `onboarding = false` skips the first-run notification prompt.

Both tmux and Herdr use `Ctrl+a`, so don't nest one inside the other. Run
`herdr config check` after editing to validate the file.
