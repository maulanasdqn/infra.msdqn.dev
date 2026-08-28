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
        "poco-f3" = {
          HostName = "127.0.0.1";
          Port = 8022;
          User = "root";
          IdentityFile = "~/.ssh/poco-f3_ed25519";
          StrictHostKeyChecking = "no";
          UserKnownHostsFile = "/dev/null";
          LogLevel = "ERROR";
        };
      };
    };

  };
}
