{
  username,
  lib,
  enableAggressiveTweaks ? false,
  ...
}:
{
  system.stateVersion = 5;
  system.primaryUser = username;

  documentation.enable = false;

  programs.zsh = {
    enableCompletion = false;
    promptInit = "";
  };

  environment.pathsToLink = [ "/share/zsh" ];

  power.sleep = lib.mkIf enableAggressiveTweaks {
    computer = "never";
    display = 10;
    harddisk = "never";
  };

  system.keyboard = lib.mkIf enableAggressiveTweaks {
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

  launchd.daemons.keyboard-remap = lib.mkIf enableAggressiveTweaks {
    serviceConfig = {
      Label = "com.local.keyboard-remap";
      ProgramArguments = [
        "/usr/bin/hidutil"
        "property"
        "--set"
        ''{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":30064771129,"HIDKeyboardModifierMappingDst":30064771113},{"HIDKeyboardModifierMappingSrc":30064771113,"HIDKeyboardModifierMappingDst":30064771129}]}''
      ];
      RunAtLoad = true;
    };
  };
}
