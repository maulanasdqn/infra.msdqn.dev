# Darwin hosts

One directory per Mac. Each is instantiated through `mkDarwinMachine` in
`flake.nix`, which supplies the shared stack (`modules/nix.nix`,
`modules/darwin`, `modules/home/darwin.nix`) plus the host module here.

| Host | Machine | `enableAggressiveTweaks` |
|---|---|---|
| `beast/` | Apple M5, 10 cores (4P + 6E), 16 GB | true |
| MacBook | single-owner | true |
| Mac mini | shared with a second account | false |

`enableAggressiveTweaks` gates machine-wide behaviour — firmware NVRAM
boot-args, HID remap, global power management, system-wide PostgreSQL and
Homebrew `cleanup = "zap"`. See `../../modules/darwin/README.md`.

Host modules are the right place for **machine-specific** settings such as Nix
build parallelism, because the Macs differ in core count and RAM. Shared policy
belongs in `modules/`.
