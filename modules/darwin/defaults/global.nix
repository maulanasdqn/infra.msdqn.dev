{ ... }:
{
  system.defaults.CustomUserPreferences = {
    "com.apple.symbolichotkeys" = {
      AppleSymbolicHotKeys = {
        "64" = {
          enabled = true;
        };
        "65" = {
          enabled = true;
        };
      };
    };

    "com.apple.Siri" = {
      StatusMenuVisible = false;
      UserHasDeclinedEnable = true;
    };

    "com.apple.gamed" = {
      Disabled = true;
    };

    "com.apple.CrashReporter" = {
      DialogType = "none";
    };

    "com.apple.TimeMachine" = {
      DoNotOfferNewDisksForBackup = true;
    };

    "com.apple.screencapture" = {
      disable-shadow = true;
    };

    "com.apple.SoftwareUpdate" = {
      AutomaticCheckEnabled = false;
      AutomaticDownload = false;
      CriticalUpdateInstall = false;
    };

    "com.apple.LaunchServices" = {
      LSQuarantine = false;
    };

    "com.apple.commerce" = {
      AutoUpdate = false;
    };

    "com.apple.desktopservices" = {
      DSDontWriteNetworkStores = true;
      DSDontWriteUSBStores = true;
    };

    "NSGlobalDomain" = {
      FocusFollowsMouse = true;

      NSAutomaticWindowAnimationsEnabled = false;
      NSWindowResizeTime = 0.001;

      NSScrollAnimationEnabled = false;

      NSAppSleepDisabled = true;
      NSDisableAutomaticTermination = true;

      NSGlassDiffusionSetting = 0;
    };

    "com.apple.finder" = {
      DisableAllAnimations = true;
    };
  };

  system.defaults.NSGlobalDomain = {
    KeyRepeat = 1;
    InitialKeyRepeat = 10;
    _HIHideMenuBar = true;
  };
}
