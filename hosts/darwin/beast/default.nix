{ ... }:
{
  networking = {
    computerName = "Beast";
    hostName = "beast";
    localHostName = "beast";
  };

  determinateNix.customSettings = {
    max-jobs = 4;
    cores = 2;
    max-substitution-jobs = 32;
    http-connections = 50;
    keep-going = true;
    warn-dirty = false;
  };
}
