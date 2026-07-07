{ username, ... }:
{
  home-manager.users.${username} = {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "*" = {
          AddKeysToAgent = "yes";
        };
        "jl" = {
          HostName = "192.168.201.28";
          User = "mrscrapersupport";
          Port = 22;
        };
      };
    };

    # NOTE: authorized_keys is intentionally NOT managed here. home-manager would
    # write it as a /nix/store symlink, which sshd StrictModes rejects ("bad
    # ownership or modes for directory /nix/store"). Inbound keys are instead set
    # via users.users.<name>.openssh.authorizedKeys.keys in modules/darwin/default.nix.
  };
}
