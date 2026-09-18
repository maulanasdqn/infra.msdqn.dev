# Sketchybar Module

Custom macOS status bar via [SketchyBar](https://felixkratz.github.io/SketchyBar/).

## Widgets

| Item       | Script       | Trigger             |
|------------|--------------|----------------------|
| Volume     | `sb-volume`  | `volume_change`      |
| Brightness | `sb-brightness` | polling (2s)      |
| Battery    | `sb-battery` | `system_woke`, polling |
| Swap       | `sb-swap`    | polling (30s)        |
| WiFi       | `sb-network` | `wifi_change`        |
| CPU        | `sb-cpu`     | polling (4s)         |

## Lockfile Guard

`sb-volume` and `sb-brightness` use `flock` to prevent zombie accumulation.
When sketchybar restarts or triggers fire faster than scripts finish,
overlapping instances exit immediately instead of piling up. Without this,
orphaned `osascript`/`python3` processes accumulate and spike load average.

## Timeout

External calls (`osascript`, `python3`) are wrapped in `timeout 5` so a
stuck subprocess is killed after 5 seconds instead of hanging indefinitely.
