# raspi services

Standalone services imported by `../default.nix`.

## parallax.nix

Runs the `parallax-server` proxy exit node (package in `pkgs/parallax`) as a
hardened `DynamicUser` systemd unit, listening on `0.0.0.0:1080`. Port 1080 is
opened in the firewall so LAN and MikroTik-forwarded clients can reach it.
