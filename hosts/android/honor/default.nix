{
  config,
  pkgs,
  ...
}:

{
  imports = [
    # Shared nix-on-droid base (packages, nix-env shim, timezone, stateVersion)
    ../default.nix
  ];

  # Honor-specific extras go here.
}
