# tmux

`default.nix` enables tmux with sensible, yank and resurrect, plus the
`tmux-startup` script (`t` alias) that creates the fixed project sessions.
`keybindings.nix` and `theme.nix` add to `extraConfig`.

## persistence.nix

Sessions, windows, panes and their working directories survive leaving tmux,
killing the server and rebooting. tmux-resurrect saves the layout to
`~/.tmux/resurrect/`, and tmux-continuum saves it every 5 minutes and
restores it automatically when a new tmux server starts.

**Why continuum is not in `plugins`.** Continuum's auto-save works by adding a
`#(continuum_save.sh)` call to `status-right`. home-manager writes the
`plugins` block before `extraConfig`, so the theme's `set -g status-right`
overwrote that hook and nothing was ever saved. `persistence.nix` loads
continuum with `lib.mkAfter`, after the theme, so the hook survives. Do not set
`status-right` in anything that loads later than this.

Manual save/restore: `prefix + C-s` / `prefix + C-r`.

## True colour

`terminal-overrides` marks both `xterm-256color` and `xterm-ghostty` (Ghostty's
`TERM`) as RGB-capable, so nvim and the Rose Pine theme get 24-bit colour
inside tmux.
