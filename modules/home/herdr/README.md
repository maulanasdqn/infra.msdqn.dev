# Herdr

Agent-aware terminal multiplexer written in Rust. Runs alongside tmux — both
are installed; use whichever fits the task.

## Config

`~/.config/herdr/config.toml` is written declaratively by home-manager. Edits
in-place are overwritten on next `darwin-rebuild switch`.

## Keybindings

Prefix is `Ctrl+a` (same as tmux). The bindings mirror the existing tmux
muscle memory:

| Key | Action |
|---|---|
| `prefix + c` | New tab |
| `prefix + n / p` | Next / previous tab |
| `prefix + 1..9` | Jump to tab |
| `prefix + Shift+T` / `Shift+X` | Rename / close tab |
| `prefix + h/j/k/l` | Focus pane left/down/up/right |
| `prefix + Shift+H/J/K/L` | Resize pane (same as tmux) |
| `prefix + \|` | Split vertical |
| `prefix + -` | Split horizontal |
| `prefix + x` | Close pane |
| `prefix + z` | Zoom pane |
| `prefix + [` | Copy mode |
| `prefix + Shift+N` / `Shift+D` | New / close workspace |
| `prefix + w` | Workspace picker |
| `prefix + g` | Session navigator (goto) |
| `prefix + d` | Detach (same as tmux) |
| `prefix + Shift+R` | Reload config |

New panes open in the current pane's directory (`new_cwd = "follow"`), like
tmux's `-c "#{pane_current_path}"`, and use zsh from nixpkgs.

`version_check` is off because Nix pins the version; `herdr update` would fight
the store path. Bump it with `nix flake update` instead.

Both tmux and Herdr use `Ctrl+a`, so don't nest one inside the other. Run
`herdr config check` after editing to validate the file.

## Theme

Uses the built-in `rose-pine` theme to match the rest of the terminal stack
(Ghostty, tmux, Neovim).
