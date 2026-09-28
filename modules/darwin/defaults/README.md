# macOS defaults

`system.defaults` and related global settings.

| File | Scope |
|---|---|
| `global.nix` | UI/UX defaults applied everywhere |
| `performance.nix` | Whole-machine performance daemons — single-owner only |

`performance.nix` is imported unconditionally; its daemons are gated by
`enableAggressiveTweaks` *inside* the module, because a module argument cannot
drive an `imports` list.

## global.nix

Kills window open/close animations and prevents macOS from throttling or
suspending background apps.

### Liquid Glass (macOS 26)

`reduceMotion`-adjacent glass tuning: the writable global key reduces the glass
blur/diffusion amount, `0` being minimal.

The real Liquid Glass killer is **Accessibility → "Reduce transparency"**
(domain `com.apple.universalaccess`). That domain is TCC/SIP-protected and
cannot be written declaratively — it must be toggled by hand in System Settings.
The writable key here is the closest declarative approximation.

### Heavy user agents

With `enableAggressiveTweaks`, a login agent runs `launchctl disable` on
background user agents that burn CPU without being used here: Game Center
(`gamed`, `gamecontrolleragentd`), Screen Time / parental controls, photo and
media analysis, `knowledgeconstructiond`, `suggestd` and `tipsd`. Errors are
discarded because some labels do not exist on every macOS release.

## performance.nix

Single-owner machines only. Disables Spotlight and Time Machine on **all**
volumes, applies kernel/network sysctl tuning (file-descriptor limits, a
larger listen backlog and SysV shared memory, no delayed ACK, 1 MiB TCP buffers,
short MSL and window scaling), sets `pmset` for maximum performance —
`highpowermode` on AC, no CPU reduction on battery, battery drain accepted, and schedules a weekly storage cleanup
every Sunday at 03:00.
