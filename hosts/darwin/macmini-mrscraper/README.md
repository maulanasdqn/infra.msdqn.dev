# Mac mini Mrscraper

The shared Mac. A second account also uses this machine, so
`enableAggressiveTweaks` is **false** here (see `../README.md`), which keeps
Homebrew `cleanup = "none"` and leaves the other account's packages alone.

## Host-only casks

`homebrew.casks` here is **merged** with the shared list in
`../../../modules/darwin/homebrew/default.nix`; nix-darwin concatenates list
options across modules, so nothing has to be repeated. Anything declared in
this file installs on the Mac mini only.

Microsoft Edge and Google Chrome live here rather than in the shared list on
purpose. The MacBook and beast run `cleanup = "zap"`, so putting a cask in the
shared list installs it on every Mac on their next rebuild, and removing it
later would uninstall it **with its data** there. A host-local entry sidesteps
both.

Nothing in the darwin config pins a default browser, so adding a browser here
does not change which one opens links.

## Nix fetches over HTTP/1.1

`determinateNix.customSettings.http2 = false` because nix's HTTP/2 fetcher
wedges on this machine. The symptom is a download that never finishes and never
errors: the process sits at 0% CPU with its sockets in `CLOSED`, holding the
build open indefinitely. It is not bandwidth and not the remote — a path nix had
been "copying" for ten minutes fetched by hand with `curl` in 0.07 s.

`stalled-download-timeout` does not rescue it. That timer only covers a transfer
that has started and then goes quiet, so a connection stuck in this state is
never abandoned and the build hangs until killed.

The cost is losing HTTP/2 multiplexing, so large fetches open more connections.
That is the cheaper side of the trade against a build that stops dead. Drop this
setting once the fetcher is fixed upstream.

## Never sleeps

`power.sleep` only exposes the computer, display and disk timers. The
`pmset-never-sleep` launchd daemon re-applies the rest at boot —
`disablesleep`, `standby`, `autopoweroff`, `hibernatemode` and `powernap` —
which nix-darwin has no options for.

## Locks after 30 minutes idle

The machine itself stays awake. Two idle timers can lock it, and both are set to
30 minutes: `power.sleep.display = 30` turns the display off, and the screen
saver's `idleTime` (seconds, per-host defaults domain `com.apple.screensaver`,
written through home-manager's `targets.darwin.currentHostDefaults`) is `1800`.
It was `60` before, which started the screen saver — and so locked the Mac —
after one minute, regardless of the display timer. The lock comes from macOS's
"require password after screen saver begins or display is turned off" setting,
which is already `immediate` here (`sysadminctl -screenLock status`). That
setting is not managed declaratively: on modern macOS the
`system.defaults.screensaver.askForPassword*` keys are ignored, and
`sysadminctl -screenLock` needs the user's password, so it was set by hand in
System Settings → Lock Screen. If the Mac stops locking, check it there first.

A process holding a `PreventUserIdleDisplaySleep` assertion (e.g.
`caffeinate -d`, a video call) keeps the display on and therefore unlocked;
`pmset -g assertions` shows who.
