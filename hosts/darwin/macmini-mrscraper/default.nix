{ ... }:
{
  # Shared Mac mini (work machine, second account: mrscrapersupport57).
  # Distinct network identity so it never collides with the MacBook on the LAN.
  networking = {
    computerName = "Mac mini Mrscraper";
    hostName = "macmini-mrscraper";
    localHostName = "macmini-mrscraper";
  };

  # Never sleep / never suspend — keep the Mac mini always-on and reachable.
  power.sleep = {
    computer = "never";
    harddisk = "never";
  };

  # `power.sleep` alone leaves several deeper idle-suspend paths active (standby,
  # hibernation, autopoweroff, Power Nap). Pin them all off via pmset so the machine
  # truly never suspends. A Mac mini is desktop/AC-only, so `-a` covers every profile.
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

  # Swap Caps Lock <-> Escape at the HID level. This is a whole-machine remap:
  # it applies to ALL users (incl. the second account mrscrapersupport57) and the
  # login window. Enabled here per explicit request, separately from the broader
  # enableAggressiveTweaks set (NVRAM boot-args, power management) which stays off.
  system.keyboard = {
    enableKeyMapping = true;
    userKeyMapping = [
      # Caps Lock -> Escape
      {
        HIDKeyboardModifierMappingSrc = 30064771129;
        HIDKeyboardModifierMappingDst = 30064771113;
      }
      # Escape -> Caps Lock
      {
        HIDKeyboardModifierMappingSrc = 30064771113;
        HIDKeyboardModifierMappingDst = 30064771129;
      }
    ];
  };
}
