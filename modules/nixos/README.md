# NixOS modules

Shared modules for the NixOS hosts (workstations and VPS).

| File | Purpose |
|---|---|
| `performance.nix` | Workstation performance tuning |
| `sops.nix` | Secret management via sops-nix |

## performance.nix

Workstation tuning. **The CPU governor is deliberately left alone.**

The laptop uses `amd-pstate-epp` in "active" mode with the
`balance_performance` energy-performance preference, which is already the
recommended setup for Zen3 laptops. Pinning the governor to `performance` on a
laptop just raises temperature and fan noise and ends up throttling — a net
loss. Do not "fix" this.

## sops.nix

Secrets are decrypted with an age key derived from the machine's **SSH host
key**, so a freshly-installed host can decrypt without manual key distribution.
The module ensures root's `.ssh` directory exists and generates the age key
from the host key at the expected location.

Declared secrets include the personal website environment, a GitHub SSH private
key, and the RAG server environment (`OPENAI_API_KEY`). `rclone_config` is also
declared here, which is why removing the VPS backup modules did not orphan it.
