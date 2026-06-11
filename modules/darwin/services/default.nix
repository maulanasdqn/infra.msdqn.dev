{ ... }:
{
  # postgres.nix is imported unconditionally; the daemon itself is gated by
  # enableAggressiveTweaks inside the module (a module arg can't drive `imports`).
  imports = [ ./postgres.nix ];
}
