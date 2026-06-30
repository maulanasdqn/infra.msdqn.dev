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
    imports = [ ./hm.nix ];
    _module.args.nixvim = nixvim;
  };
}
