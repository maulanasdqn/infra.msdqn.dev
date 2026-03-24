{
  pkgs,
  username,
  ...
}:
let
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [ "34" ];
    buildToolsVersions = [ "34.0.0" ];
    includeEmulator = true;
    includeSources = false;
    includeSystemImages = true;
    systemImageTypes = [ "google_apis" ];
    abiVersions = [ "x86_64" ];
    includeNDK = false;
    includeExtras = [ ];
  };
in
{
  # Accept Android SDK license
  nixpkgs.config.android_sdk.accept_license = true;

  # User groups for KVM access
  users.users.${username}.extraGroups = [
    "kvm"
  ];

  # Android SDK + tools
  environment.systemPackages = [
    androidComposition.androidsdk
    pkgs.android-tools # adb, fastboot
  ];

  # Environment variables
  environment.sessionVariables = {
    ANDROID_HOME = "${androidComposition.androidsdk}/libexec/android-sdk";
    ANDROID_SDK_ROOT = "${androidComposition.androidsdk}/libexec/android-sdk";
  };
}

