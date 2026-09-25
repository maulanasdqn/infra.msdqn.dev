# AeroSpace

Tiling window manager for macOS. Config version 2.

## The top gap is derived, not eyeballed

AeroSpace measures `outer.top` from the **system work-area top**, but the
sketchybar islands are drawn from **screen-top**. The two live in different
origins, so the offset has to be cancelled out:

```
topGap       = islandBottom + desiredGap - workAreaTop
islandBottom = bar y_offset + (bar height + island height) / 2
             = 8 + (34 + 30) / 2
             = 40px
```

If you change the sketchybar geometry — `y_offset`, bar height, or island
height — this calculation must be redone or the gap will visibly drift. See
`../sketchybar/README.md`.

## Terminal launch path

`alt-enter` opens Ghostty from `~/Applications/Home Manager Apps/`, which
home-manager always creates, not from `Home Manager Trampolines/`. The
trampolines come from mac-app-util, whose SBCL binary currently fails on this
macOS (`failed to allocate 1048576 bytes at 0x300100000`), so that folder can
be stale or missing new apps. `open -b com.mitchellh.ghostty` at startup
resolves through Launch Services and does not depend on either folder.
