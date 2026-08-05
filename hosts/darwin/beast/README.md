# beast — Apple M5

10 cores (4 performance + 6 efficiency), **16 GB RAM**, macOS 26.

## Nix build parallelism

RAM is the binding constraint here, not cores. Determinate's defaults resolve to
`max-jobs = 10` (one per core) with `cores = 0` (unlimited threads per job),
which permits **up to 100 concurrent compile threads on 10 cores**. On 16 GB
that swaps rather than computes — this machine already sits at ~3 GB of its
4 GB swap in ordinary use, so the default is actively slower than a lower
setting, not merely risky.

| Setting | Value | Reasoning |
|---|---|---|
| `max-jobs` | 4 | Concurrent derivations. Peak memory is roughly per-job, so this caps RAM, not CPU. |
| `cores` | 2 | Threads per job → 8 total, close to the 4 P-cores plus headroom. Beyond this work spills onto E-cores, which are much slower for compilation. |
| `max-substitution-jobs` | 32 | This Mac substitutes far more than it builds. Downloads are I/O bound and cheap in memory. |
| `http-connections` | 50 | Same reasoning — parallel fetch is the real bottleneck for a config machine. |
| `keep-going` | true | Build everything buildable before reporting failure. |
| `warn-dirty` | false | Silences the dirty-tree warning on every local eval. |

`profiles/server.nix` makes the same trade in the other direction for the VPS
(`max-jobs = 1`, `cores = 2`) because that box has less RAM still.

If you raise these, watch `sysctl vm.swapusage` during a large build. Swap
growth means `max-jobs` is too high; idle P-cores with free RAM mean it is too
low.

## Not enabled: the Linux builder

`determinateNix.nixosVmBasedLinuxBuilder` would let this Mac build
`x86_64-linux` closures locally instead of on the VPS. It is deliberately off —
the VM wants several GB of RAM this machine does not have. The Hostinger VPS
builds its own system instead (see `../../vps/hostinger/README.md`).
