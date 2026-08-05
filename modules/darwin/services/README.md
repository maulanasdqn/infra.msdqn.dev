# Darwin services

LaunchDaemons managed by nix-darwin.

`postgres.nix` is imported unconditionally; the daemon itself is gated by
`enableAggressiveTweaks` inside the module, because a module argument cannot
drive an `imports` list.

## PostgreSQL

System-wide server on **port 5433**, trust auth. Single-owner machines only.

**Currently off.** Dev databases live in containers under Colima, and this
daemon was failing to start anyway — `org.nixos.postgresql` exited 2 at every
login. Flip the gate to `true` to bring the system-wide server back.
