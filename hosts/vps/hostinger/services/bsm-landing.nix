{ ... }:
{
  # BSmart Landing — static Vite/React site served by NixOS nginx (ACME TLS).
  # The nginx vhost for `bsm.art` is defined by the bsm-landing nixosModule.
  services.bsmart-landing = {
    enable = true;
    domain = "bsm.art";
  };
}
