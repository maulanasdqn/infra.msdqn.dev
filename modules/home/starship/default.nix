{ username, ... }:
{

  home-manager.users.${username}.imports = [ ./hm.nix ];
}
