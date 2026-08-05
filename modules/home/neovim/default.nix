{
  username,
  nixvim,
  ...
}:
{

  home-manager.users.${username} = {

    imports = [
      ./hm.nix
      ./plugins/claudecode.nix
    ];
    _module.args.nixvim = nixvim;
  };
}
