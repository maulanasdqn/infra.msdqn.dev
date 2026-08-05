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

  };
}
