{
  username,
  nixvim,
  ...
}:
{
  # NixOS/Darwin wrapper: mount the reusable home-manager neovim config under
  # the user's home-manager. The actual config lives in ./hm.nix so it can also
  # be imported directly by single-user home-manager (e.g. nix-on-droid/honor).
  home-manager.users.${username} = {
    # ./hm.nix is the shared (mobile-safe) config; stynx builds a Rust CLI from
    # source so it's desktop-only and added here rather than in the shared set.
    imports = [
      ./hm.nix
      ./plugins/stynx.nix
    ];
    _module.args.nixvim = nixvim;
  };
}
