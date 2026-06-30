{
  pkgs,
  username,
  ...
}:
let
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [
      "34"
      "35"
    ];
    buildToolsVersions = [
      "34.0.0"
      "35.0.0"
    ];
    includeNDK = true;
    ndkVersions = [ "27.2.12479018" ];
    includeEmulator = false;
    includeSystemImages = false;
    includeSources = false;
  };
  androidSdk = androidComposition.androidsdk;
  androidHome = "${androidSdk}/libexec/android-sdk";
in
{
  nixpkgs.config.android_sdk.accept_license = true;

  environment.systemPackages = with pkgs; [
    androidSdk
    jdk17
    gradle
    kotlin
    scrcpy
  ];

  environment.variables = {
    ANDROID_HOME = androidHome;
    ANDROID_SDK_ROOT = androidHome;
    ANDROID_NDK_ROOT = "${androidHome}/ndk/27.2.12479018";
    JAVA_HOME = "${pkgs.jdk17}/lib/openjdk";
    GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidHome}/build-tools/35.0.0/aapt2";
  };
}
