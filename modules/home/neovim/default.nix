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
    # ./hm.nix is the shared (mobile-safe) config. stynx (Rust-from-source) and
    # the Claude Code integration are desktop-only — added here, not in the
    # shared set, so nix-on-droid/honor stays lean and free of the CC plugin.
    imports = [
      ./hm.nix
      ./plugins/stynx.nix
      ./plugins/claudecode.nix
    ];
    _module.args.nixvim = nixvim;
  };
}
