{ ... }:
{
  # Shared Mac mini (work machine, second account: mrscrapersupport57).
  # Distinct network identity so it never collides with the MacBook on the LAN.
  networking = {
    computerName = "Mac mini Mrscraper";
    hostName = "macmini-mrscraper";
    localHostName = "macmini-mrscraper";
  };
}
