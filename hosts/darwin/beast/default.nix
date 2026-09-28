{ ... }:
{
  networking = {
    computerName = "Beast";
    hostName = "beast";
    localHostName = "beast";
  };

  determinateNix.customSettings = {
    max-jobs = "auto";
    cores = 4;
    max-substitution-jobs = 64;
    http-connections = 128;
    keep-going = true;
    warn-dirty = false;
  };
}
