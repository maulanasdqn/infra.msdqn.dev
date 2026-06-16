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
      # macOS 26 "Liquid Glass" — reduce the glass blur/diffusion amount.
      # Writable global key (unlike reduceTransparency below). 0 = minimal.
      NSGlassDiffusionSetting = 0;
    };

    # NOTE: the real Liquid Glass killer is Accessibility > "Reduce transparency"
    # (domain com.apple.universalaccess). That domain is TCC/SIP-protected on
    # modern macOS — `defaults write` fails with "Could not write domain
    # com.apple.universalaccess; exiting" even run interactively as the user, so it
    # CANNOT be set from Nix, a launchd agent, or any script. It must be toggled by
    # hand in System Settings > Accessibility > Display ("Reduce transparency" +
    # "Reduce motion"); it then persists across reboots. NSGlassDiffusionSetting
    # above is the only glass knob we can set declaratively.

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
