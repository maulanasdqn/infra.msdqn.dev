{ ... }:
{
  # Kolaborium — static Vite/React site served by NixOS nginx (ACME TLS).
  # The nginx vhost for `kolaborium.com` (+ www redirect) is defined by the
  # kolaborium nixosModule.
  services.kolaborium = {
    enable = true;
    domain = "kolaborium.com";
  };
}
