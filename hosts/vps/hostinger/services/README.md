# Hostinger VPS — services

Per-app modules for the Hostinger box (`72.62.125.38`). Six KYA apps run here,
each fully self-contained: its own Postgres, podman network, GitHub Actions
runner, forced-command SSH key and nginx vhost. **Nothing is shared between them
except the machine.**

## The six apps

| Module | App | Port | Domain | Extras |
|---|---|---|---|---|
| `kya-field-quote.nix` | Field Quote | 3003 | `kya-fq.stynx.app` | — |
| `kya-sales-reporting.nix` | Sales Reconciliation & Commission Dashboard | 3002 | `kya-sr.stynx.app` | Redis |
| `kya-bond-closeout.nix` | Surety bond closeout automation | 3004 | `kya-bc.stynx.app` | Redis |
| `kya-bill-pay.nix` | AP Invoice Automation | 3001 | `kya-bp.stynx.app` | Redis + BullMQ worker |
| `kya-entity-license-renewal.nix` | Entity License Renewal | 3005 | `kya-el.stynx.app` | Redis db 4 + BullMQ worker |
| `kya-field-checklist.nix` | Field PM Checklist | 3006 | `kya-fc.stynx.app` | Redis db 5 + BullMQ worker |

Field-quote was migrated off DigitalOcean App Platform. Its image is built **on
the VPS** from `/opt/kya-group` and tagged `localhost/kya-field-quote:latest`.

## Deploy flow

GitHub Actions (`s52ai/kya-group`) pipes `git archive HEAD` over SSH into a
forced-command script on the box. That script rebuilds the image locally,
restarts the app, and healthchecks it — `ssh`'s exit code is the deploy status.

The CI key is `restrict,command="…"`, so it can run **only** that script, never
an arbitrary root shell. It merges with root's normal keys from
`profiles/base.nix`.

The Docker build doubles as the typecheck gate: a broken build never restarts
the app. Migrations run **before** the app rolls — `systemctl restart
kya-*-migrate.service` blocks on the oneshot, so a failed migration aborts the
deploy (`set -e`) and leaves the old app running.

## Runners

One self-hosted runner per app, labelled `kya-fq` / `kya-sr` / `kya-bc` /
`kya-bp` / `kya-elr` / `kya-fc` so each workflow lands on its own. They exist because the s52ai org's
GitHub-hosted minutes are billing-blocked. Each runs as an unprivileged dynamic
user and can only trigger a root deploy through the forced-command key above.

Registration tokens live in `/etc/github-runner-*.token` (0600, created on the
VPS). Note `kya-fq` uses `/etc/github-runner-kya.token`, not `-kya-fq`. Refresh:

```sh
gh api -X POST repos/s52ai/kya-group/actions/runners/registration-token --jq .token
```

**Tokens expire after one hour.** Anything that re-registers a runner — notably
changing `workDir` — consumes a fresh one, so reissue immediately before such a
change or the runners come back offline.

### Do not point `workDir` at `/var/lib/github-runner/<name>`

That path is already the systemd `StateDirectory` (a symlink to
`/var/lib/private/github-runner/<name>`). The upstream module runs
`find -H "$WORK_DIRECTORY" -mindepth 1 -delete` on every start; `-H` follows the
symlink and deletes the runner's own `.credentials` and `.current-token`, after
which the unit fails at `status=226/NAMESPACE`. A work directory must be a
distinct path.

Left unset, `workDir` defaults to the systemd `RuntimeDirectory` under `/run` —
a 4 GB **tmpfs**, i.e. RAM. Checkouts and `pnpm install` therefore run in memory,
which is why the `CI` workflow fails with `ENOSPC` while the real disk is nearly
empty. Deploy workflows are unaffected: they only `git archive | ssh`.

`kya-ci-runner-env.nix` supplies the environment those runners need:

- `NIX_LD` — `actions/setup-node` and `moonrepo/setup-toolchain` download
  generic-linux binaries, and NixOS refuses to exec them unless the stub loader
  points at a real dynamic linker. `programs.nix-ld` sets this for login shells,
  but a systemd service gets a clean environment, so it must be set explicitly
  or every `node` invocation hits the stub and fails.
- A CA bundle — `moonrepo/setup-toolchain` runs proto, which shells out to
  `curl` to fetch moon and needs it to verify the download over TLS.

## Secrets

Read from env files created on the VPS by hand, mode 0600 — never in git:

```
/etc/kya-{fq,sr,bc,bp,el,fc}-postgres.env   POSTGRES_USER / PASSWORD / DB
/etc/kya-{fq,sr,bc,bp,el,fc}.env            DATABASE_URL, BETTER_AUTH_*, WEB_ORIGIN,
                                            admin bootstrap
```

`kya-bp.env` additionally carries the optional `ANTHROPIC` / `GMAIL_*` /
`SAGE_*` / `SHEETS_*` / `PHASE2_BILLS_ENABLED` integration secrets.

## Gotchas

**Postgres uid.** `postgres:17-alpine` runs as **uid 70**, not the Debian
images' 999. Getting this wrong is silent until `systemd-tmpfiles-resetup`
re-asserts ownership on an unrelated rebuild, after which new backends cannot
read the data directory. Hence `"d /var/lib/kya-*/postgres 0700 70 70 -"`.

**Custom podman-run units.** The apps use hand-written units rather than
`oci-containers` because the image is a locally-built `localhost/` tag that must
never be pulled.

**Private networks.** Each app gets its own podman network so it resolves its DB
by container name.

**Migrations are idempotent** and safe to re-run on every deploy.

**DNS is grey-cloud.** All six domains are Cloudflare A records straight to
`72.62.125.38`, DNS-only, so ACME HTTP-01 reaches the origin. A side effect is
that nginx sees real client IPs, so fail2ban bans real users rather than
Cloudflare edges.

**Activation downtime.** A `nixos-rebuild switch` stops every container,
including Postgres, and each app's `*-migrate.service` is a `requires` + `before`
dependency that must wait for Postgres, migrate, and bootstrap before the app may
start. Budget roughly **two minutes of 502s** on all six apps per deploy.

## Removed

Only the modules above remain; everything else in this directory was
deleted as dead config.

`backup.nix` / `yes-date-me-backup.nix` dumped a host-local Postgres via
`sudo -u postgres`, but that user does not exist here — Postgres runs only
inside containers. They failed nightly with `unknown user postgres`, backing up
nothing.

`rkm-backend.nix` (Rust — kept off the box to avoid a cargo compile),
`roasting-startup.nix` and `n8n.nix` were all unimported. The `rkm-backend` and
`roasting-startup` flake inputs went with them; the former was a `git+ssh://`
URL, so evaluation no longer needs SSH auth to that private repo.

The SIEM/SOAR stack (fluent-bit, wazuh agent, suricata, aysiem heartbeat) was
removed entirely, along with auditd. See `../README.md`.
