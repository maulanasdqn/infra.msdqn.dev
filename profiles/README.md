# Profiles

Shared configuration layers. Hosts import a profile rather than repeating
policy.

| File | Scope |
|---|---|
| `base.nix` | Common to every machine — users, SSH keys, nix settings |
| `server.nix` | Headless servers; imports `base.nix` |

## base.nix

Validates the passed config and only creates a non-root user when `username` is
not `"root"` — nix-on-droid and some VPS roles run as root only.

## server.nix

### Build safety

`zramSwap` is enabled (zstd, 50% of RAM) to prevent OOM during builds, and Nix
is deliberately throttled: `max-jobs = 1`, `cores = 2`. A small VPS will
otherwise be killed by its own rebuild.

Substituters include `msdqn.cachix.org` alongside `cache.nixos.org`.

Timezone is forced to UTC. `system.autoUpgrade` is off — deploys are manual from
GitHub.

### Network hardening

Firewall on, **ping responses disabled**, reverse-path drops and refused
connections logged. Only 22/80/443 open.

SSH: no passwords, no keyboard-interactive, no X11 forwarding, no agent
forwarding, `PermitRootLogin = "prohibit-password"`, `MaxAuthTries = 3`,
`LoginGraceTime = 20`. TCP forwarding stays on.

`boot.kernel.sysctl` covers reverse-path filtering, redirect and source-route
rejection, SYN cookies, martian logging, then kernel hardening
(`kptr_restrict`, `dmesg_restrict`, `perf_event_paranoid`, `yama.ptrace_scope`,
`unprivileged_bpf_disabled`, `bpf_jit_harden`) and TCP hardening (`tcp_rfc1337`,
timestamps off).

### nginx

Brotli module is loaded for app modules that use it, but **both
`recommendedGzipSettings` and `recommendedBrotliSettings` are force-disabled** —
app modules add their own and would otherwise conflict. Body limit 100 MB,
proxy timeout 300 s, explicit modern cipher suite and curve list.

`appendHttpConfig` defines the rate-limit zones (note: these are nginx config
comments inside a Nix string, so they are not Nix comments and remain in the
file):

| Zone | Rate | For |
|---|---|---|
| `api_limit` | 10 r/s | general API |
| `auth_limit` | 5 r/s | auth endpoints |
| `static_limit` | 50 r/s | static assets |
| `ai_limit` | 2 r/s | LLM calls (expensive) |
| `upload_limit` | 5 r/min | uploads |
| `conn_per_ip` | — | connection cap per IP |

Both limit statuses return 429. `server_tokens`, `client_max_body_size` and
`keepalive_timeout` are already set by `recommendedOptimisation` /
`clientMaxBodySize` and must not be duplicated here.

A default `"_"` vhost returns a plain-text liveness string.

### fail2ban

Global `maxretry = 3`, `bantime = 1h`, with escalation up to 168 h
(multipliers `1 2 4 8 16 32 64`). Jails: `nginx-http-auth` (auth failures),
`nginx-botsearch` (bots), `nginx-limit-req` (429s), `nginx-bad-request`
(400s — scanners), `nginx-req-limit` (repeated 403/404 — scanners). The last two
use custom filters written via `environment.etc`.

Because the app domains are grey-cloud, nginx logs real client IPs, so these
jails ban actual users. A single office IP tripping a jail takes out every app
on the box for that network at once.

### Containers

podman with `dockerCompat`, weekly auto-prune, DNS enabled on the default
network. `oci-containers.backend = "podman"`.

`security.lockKernelModules` is **false** — required for containers.
`protectKernelImage` stays on.

### Audit (removed)

`security.auditd` and `security.audit` are explicitly disabled. The old
`-S execve` rule logged every process execution and, with no rotation keys in
the NixOS-generated `auditd.conf`, grew `/var/log/audit/audit.log` to 68 GB. Its
only consumers were fluent-bit and the wazuh agent, both removed. See
`../hosts/vps/hostinger/README.md`.
