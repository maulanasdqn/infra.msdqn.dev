{
  config,
  pkgs,
  lib,
  username,
  enableTilingWM ? false,
  sshKeys ? [ ],
  ...
}:
{
  imports = [
    ./system
    ./security
    ./packages
    ./defaults
    ./fonts
    ./homebrew
    ./services
    ./aerospace
    ./sketchybar
    ./android.nix
  ];

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";

    openssh.authorizedKeys.keys = sshKeys;
  };
}
