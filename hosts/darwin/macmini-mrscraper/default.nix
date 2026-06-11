{ ... }:
{
  networking = {
    computerName = "Mac mini Mrscraper";
    hostName = "macmini-mrscraper";
    localHostName = "macmini-mrscraper";
  };

  power.sleep = {
    computer = "never";
    harddisk = "never";
  };

  launchd.daemons.pmset-never-sleep = {
    serviceConfig = {
      Label = "com.local.pmset-never-sleep";
      ProgramArguments = [
        "/bin/sh"
        "-c"
        ''
          /usr/bin/pmset -a sleep 0 disablesleep 1 \
            standby 0 autopoweroff 0 hibernatemode 0 powernap 0
        ''
      ];
      RunAtLoad = true;
    };
  };

  system.keyboard = {
    enableKeyMapping = true;
    userKeyMapping = [
      {
        HIDKeyboardModifierMappingSrc = 30064771129;
        HIDKeyboardModifierMappingDst = 30064771113;
      }
      {
        HIDKeyboardModifierMappingSrc = 30064771113;
        HIDKeyboardModifierMappingDst = 30064771129;
      }
    ];
  };
}
