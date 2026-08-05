# sketchybar

Status bar, drawn as separate "islands" rather than one unified bar.

## Geometry feeds AeroSpace

Island layout: bar `y_offset` 8, bar height 34, island height 30, giving an
island bottom edge at 40px from screen-top, with a uniform 10px gap around.

`../aerospace/README.md` derives its `outer.top` gap from exactly these
numbers. Change one and you must redo the other.

## Workspace indicator

Responds to the `aerospace_workspace_change` event.

- `$NAME` is set by sketchybar itself (e.g. `space.3`)
- `$AEROSPACE_FOCUSED_WORKSPACE` arrives via the trigger payload

## CPU item

A single instantaneous `top` sample (user + sys), normalised to 100% across all
cores. `-n 0` skips the process list to keep it cheap.

Colour ramp: foam → gold at ≥50% → love at ≥85%.

**`/usr/bin/top` is hardcoded on purpose.** The `procps` build on PATH cannot
read RSS on macOS 26 — that needs an entitlement only Apple's binary carries.

## Native menu-bar mirroring

Requires Screen Recording permission to be granted, or the mirrored items render
empty.
