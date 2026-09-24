# zsh

`default.nix` is a NixOS/Darwin wrapper around the reusable `./hm.nix`
home-manager module, so the same zsh config can be imported directly by
single-user home-manager (nix-on-droid / `honor`). See `../README.md`.

## aliases.nix

**Android mirroring.** The scrcpy alias mirrors a device borderless at the same
height as iPhone Mirroring's largest zoom (898px window). scrcpy cannot draw
rounded corners or a phone frame, so borderless is the closest "phone-screen"
look. Width follows the device aspect ratio, and `command` skips the alias to
avoid a recursion loop.

## oh-my-zsh tmux plugin

`hm.nix` enables the oh-my-zsh `tmux` plugin. Running bare `tmux` attaches to
the existing session instead of starting a new one (`ZSH_TMUX_AUTOCONNECT`),
and it adds the `ta`, `ts`, `tl`, `tkss`, `tksv` aliases. Autostart is off so
every new terminal does not jump into tmux. `ZSH_TMUX_FIXTERM` is off so the
plugin does not override `default-terminal` (`tmux-256color`), and
`ZSH_TMUX_CONFIG` points at the home-manager config in `~/.config/tmux/`
instead of the plugin's `~/.tmux.conf` default. Layout persistence itself comes
from resurrect/continuum, see `../tmux/README.md`.

## Startup performance

Shell startup is dominated by `compinit`, so `hm.nix` avoids doing anything
twice or for nothing:

- No oh-my-zsh theme (`theme = ""`); starship draws the prompt on every host
  that imports `hm.nix`.
- No `z` plugin. zoxide already provides `z`, and the plugin added a precmd
  hook that rewrote `~/.z` on every prompt.
- fzf keybindings come only from `programs.fzf`; `initContent` does not
  re-evaluate `fzf --zsh`.
- `ZSH_DISABLE_COMPFIX` skips `compaudit`'s permission scan of `fpath` (all
  store paths, single-user machine). `DISABLE_AUTO_UPDATE` because oh-my-zsh
  is pinned by Nix. `DISABLE_MAGIC_FUNCTIONS` drops url-quote-magic and
  bracketed-paste-magic, which make pasting long text slow.

The system side lives in `../../darwin/system/default.nix`: nix-darwin's
`/etc/zshrc` ran its own `compinit` and `promptinit` before oh-my-zsh ran
`compinit` again. See that folder's README.
