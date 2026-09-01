{
  pkgs,
  iosRuntime ? null,
}:

let
  runtimeSub =
    sub:
    builtins.path {
      path = "${iosRuntime}/${sub}";
      name = builtins.replaceStrings [ "/" " " "." ] [ "-" "-" "-" ] sub;
    };

  nixbind = pkgs.callPackage ./nixbind.nix { };

  hardening = pkgs.callPackage ./hardening.nix { };

  adblock = pkgs.callPackage ./adblock.nix { };

  nixenter = pkgs.callPackage ./nixenter.nix { };

  sshd = pkgs.callPackage ./sshd.nix { };

  stealth = pkgs.callPackage ./stealth.nix { };

  iossounds =
    if iosRuntime == null then
      null
    else
      pkgs.callPackage ./iossounds.nix {
        uiSounds = runtimeSub "System/Library/Audio/UISounds";
        alertTones = runtimeSub "System/Library/PrivateFrameworks/ToneLibrary.framework/AlertTones";
        alarmTones = runtimeSub "System/Library/PrivateFrameworks/ToneLibrary.framework/AlarmWakeUpRingtones";
      };

  available = [
    nixbind
    hardening
    adblock
    nixenter
    sshd
    stealth
  ]
  ++ pkgs.lib.optional (iossounds != null) iossounds;
in

{
  inherit
    nixbind
    hardening
    adblock
    nixenter
    sshd
    stealth
    iossounds
    ;

  all = pkgs.linkFarm "poco-f3-magisk-modules" (
    map (m: {
      name = builtins.baseNameOf (builtins.head (builtins.attrNames (builtins.readDir m)));
      path = "${m}/${builtins.head (builtins.attrNames (builtins.readDir m))}";
    }) available
  );
}
