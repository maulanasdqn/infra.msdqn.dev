{ ... }:
{
  system.defaults.CustomUserPreferences = {
    "com.apple.symbolichotkeys" = {
      AppleSymbolicHotKeys = {
        "64" = { enabled = true; };
        "65" = { enabled = true; };
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
      # Kill window open/close animations
      NSAutomaticWindowAnimationsEnabled = false;
      NSWindowResizeTime = 0.001;
      # Kill scroll animation
      NSScrollAnimationEnabled = false;
      # Prevent macOS from throttling/suspending background apps
      NSAppSleepDisabled = true;
      NSDisableAutomaticTermination = true;
    };

    # NOTE: com.apple.universalaccess (reduceTransparency / reduceMotion) removed —
    # it's a protected domain on modern macOS; `defaults write` fails with
    # "Could not write domain com.apple.universalaccess; exiting", which aborts the
    # whole activation. Set these by hand in System Settings > Accessibility if wanted.

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
