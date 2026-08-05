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

## performance.nix

Single-owner machines only. Disables Spotlight and Time Machine on **all**
volumes, applies kernel/network sysctl tuning, sets `pmset` for maximum
performance (battery drain accepted), and schedules a weekly storage cleanup
every Sunday at 03:00.
