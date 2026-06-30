{
  username,
  ...
}:
{
  # NixOS/Darwin wrapper around the reusable ./hm.nix home-manager module so
  # the same zsh config can be imported directly by single-user home-manager
  # (e.g. nix-on-droid/honor).
  home-manager.users.${username}.imports = [ ./hm.nix ];
}
