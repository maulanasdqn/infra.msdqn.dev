{ ... }:
{
  # performance.nix is imported unconditionally but its daemons are gated by
  # enableAggressiveTweaks inside the module (a module arg can't drive `imports`).
  imports = [
    ./dock.nix
    ./finder.nix
    ./global.nix
    ./trackpad.nix
    ./performance.nix
  ];
}
