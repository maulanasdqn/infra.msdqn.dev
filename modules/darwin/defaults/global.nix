{ lib, ... }:
{
  system.defaults.NSGlobalDomain = {
    AppleShowAllExtensions = true;

    ApplePressAndHoldEnabled = false;
    KeyRepeat = 1;
    InitialKeyRepeat = 10;

    _HIHideMenuBar = false;

    AppleEnableSwipeNavigateWithScrolls = false;

    AppleFontSmoothing = 0;

    NSAutomaticCapitalizationEnabled = false;
    NSAutomaticDashSubstitutionEnabled = false;
    NSAutomaticPeriodSubstitutionEnabled = false;
    NSAutomaticQuoteSubstitutionEnabled = false;
    NSAutomaticSpellingCorrectionEnabled = false;
  };

  system.defaults.CustomUserPreferences = {
    "com.apple.symbolichotkeys" = {
      AppleSymbolicHotKeys = {
        "64" = { enabled = false; };
        "65" = { enabled = false; };
      };
    };

    "com.apple.Siri" = {
      StatusMenuVisible = false;
      UserHasDeclinedEnable = true;
    };

    "com.apple.gamed" = {
      Disabled = true;
    };

    "com.apple.mail" = {
      DisableInlineAttachmentViewing = true;
      AddressesIncludeNameOnPasteboard = false;
    };

    "com.apple.Safari" = {
      IncludeInternalDebugMenu = true;
      WebKitDeveloperExtrasEnabledPreferenceKey = true;
    };

    "com.apple.CrashReporter" = {
      DialogType = "none";
    };

    "com.apple.desktopservices" = {
      DSDontWriteNetworkStores = true;
      DSDontWriteUSBStores = true;
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

    "com.apple.appstore" = {
      ShowDebugMenu = true;
      WebKitDeveloperExtras = true;
    };
  };

  system.defaults.WindowManager = {
    EnableStandardClickToShowDesktop = false;
  };
}
