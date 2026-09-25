# ghostty

The macOS terminal. It replaced kitty: measured on the MacBook with default
settings, Ghostty used about 83 MB against kitty's 156–187 MB, and it can hide
the title bar and traffic-light buttons while keeping native rounded corners.

**Same look as the old kitty setup.** Rose Pine colours (the same 16-colour
palette), JetBrainsMono Nerd Font 14, 90% opacity with blur 50, 10px padding,
blinking block cursor, Option as Alt, no close confirmation, and full
clipboard access for programs (OSC 52), as kitty had.

**Window.** `macos-titlebar-style = hidden` removes the title bar and buttons
but keeps the rounded corners and shadow, so no border tool is needed.

**Package.** `ghostty-bin` is the upstream signed macOS build; nixpkgs'
source-built `ghostty` does not build on Darwin.

**Shift+Enter** sends `ESC [13;2u` so Claude Code and other TUIs can tell it
apart from Enter (inserts a newline instead of submitting).

**SSH.** Ghostty sets `TERM=xterm-ghostty`, which servers usually lack.
`ssh-terminfo` copies the terminfo entry to the host on first connect and
`ssh-env` falls back to `xterm-256color` when that is not possible, so
remote shells, tmux and nvim do not break.
