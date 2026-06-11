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
    # Populates /etc/ssh/nix_authorized_keys.d/${username}, which nix-darwin's
    # sshd AuthorizedKeysCommand reads as root. Unlike a home-managed
    # ~/.ssh/authorized_keys (a /nix/store symlink that sshd StrictModes rejects
    # with "bad ownership or modes for directory /nix/store"), this path works.
    openssh.authorizedKeys.keys = sshKeys;
  };
}
