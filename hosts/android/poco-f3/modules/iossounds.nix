{
  lib,
  stdenvNoCC,
  ffmpeg,
  zip,
  uiSounds,
  alertTones,
  alarmTones,
}:

let
  uiMap = {
    "Effect_Tick" = "key_press_modifier";
    "Lock" = "lock";
    "Unlock" = "Tink";
    "KeypressStandard" = "key_press_click";
    "KeypressDelete" = "key_press_delete";
    "KeypressReturn" = "key_press_modifier";
    "KeypressSpacebar" = "key_press_click";
    "KeypressInvalid" = "keyboard_press_clear";
    "camera_click" = "photoShutter";
    "camera_focus" = "focus_change_small";
    "VideoRecord" = "begin_record";
    "VideoStop" = "end_record";
    "LowBattery" = "low_power";
    "ChargingStarted" = "connect_power";
    "WirelessChargingStarted" = "connect_power";
    "Dock" = "connect_power";
    "Undock" = "navigation_pop";
    "NFCSuccess" = "payment_success";
    "NFCFailure" = "payment_failure";
    "NFCInitiated" = "nfc_scan_complete";
    "NFCTransferComplete" = "NFCCardComplete";
    "NFCTransferInitiated" = "nfc_scan_complete";
    "Trusted" = "AuthenticationMatch_Full";
    "InCallNotification" = "acknowledgment_received";
  };

  extraNotifications = {
    "iOS_Tri-tone" = "sms-received1";
    "iOS_Alert_2" = "sms-received2";
    "iOS_Alert_3" = "sms-received3";
    "iOS_Alert_4" = "sms-received4";
    "iOS_Alert_5" = "sms-received5";
    "iOS_Alert_6" = "sms-received6";
    "iOS_New_Mail" = "new-mail";
    "iOS_Mail_Sent" = "mail-sent";
    "iOS_Received" = "ReceivedMessage";
    "iOS_Sent" = "SentMessage";
  };

  uiLines = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (dst: src: ''norm "${uiSounds}/${src}.caf" "$UIDIR/${dst}.ogg"'') uiMap
  );

  notifLines = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      dst: src: ''norm "${uiSounds}/${src}.caf" "$NDIR/${dst}.ogg"''
    ) extraNotifications
  );
in

stdenvNoCC.mkDerivation {
  pname = "magisk-iossounds";
  version = "1.0";

  dontUnpack = true;
  nativeBuildInputs = [
    ffmpeg
    zip
  ];

  buildPhase = ''
    runHook preBuild

    OUT=mod/system/product/media/audio
    UIDIR=$OUT/ui
    NDIR=$OUT/notifications
    RDIR=$OUT/ringtones
    ADIR=$OUT/alarms
    mkdir -p "$UIDIR" "$NDIR" "$RDIR" "$ADIR" mod/META-INF/com/google/android

    # Apple ships these far below full scale (Tock averages -24.7 dB,
    # keyboard_press_normal -43.9 dB) and Android replays UI effects quietly on
    # top of that, so an unmodified transcode is inaudible. Peak-normalise to
    # -1 dBFS. -map 0:a:0 skips the 'ahap' haptic streams inside .m4r tones,
    # which otherwise abort the transcode.
    norm() {
      local src="$1" dst="$2" peak gain
      [ -f "$src" ] || { echo "missing: $src" >&2; return 0; }
      peak=$(ffmpeg -hide_banner -i "$src" -af volumedetect -f null - 2>&1 \
             | sed -n 's/.*max_volume: \(-*[0-9.]*\) dB.*/\1/p' | head -1)
      peak="''${peak:-0}"
      gain=$(awk -v p="$peak" 'BEGIN{printf "%.2f", -1.0 - p}')
      ffmpeg -hide_banner -loglevel error -y -i "$src" \
        -map 0:a:0 -vn -af "volume=''${gain}dB" \
        -c:a libvorbis -q:a 6 -ar 44100 "$dst"
    }

    echo "==> UI sounds"
    ${uiLines}

    echo "==> extra notification tones"
    ${notifLines}

    echo "==> classic alert tones"
    for f in "${uiSounds}"/New/*.caf; do
      [ -e "$f" ] || continue
      b=$(basename "$f" .caf)
      norm "$f" "$NDIR/iOS_$b.ogg"
    done

    # AlertTones nest under Classic/ Modern/ EncoreInfinitum/ and reuse names
    # across those folders, so the variant has to stay in the filename.
    echo "==> alert tones -> notifications + ringtones"
    find "${alertTones}" -name '*.m4r' | sort | while read -r f; do
      b=$(basename "$f" .m4r)
      v=$(basename "$(dirname "$f")")
      case "$v" in AlertTones) v="" ;; *) v="''${v}_" ;; esac
      norm "$f" "$NDIR/iOS_''${v}''${b}.ogg"
      norm "$f" "$RDIR/iOS_''${v}''${b}.ogg"
    done

    echo "==> alarms"
    find "${alarmTones}" -name '*.m4r' | sort | while read -r f; do
      b=$(basename "$f" .m4r)
      norm "$f" "$ADIR/iOS_$b.ogg"
    done
    norm "${uiSounds}/alarm.caf" "$ADIR/iOS_Alarm.ogg"

    cat > mod/module.prop <<'PROP'
    id=iossounds
    name=iOS system sounds
    version=v1.0
    versionCode=1
    author=ms
    description=Replaces Android UI sounds, notification tones, ringtones and alarms with peak-normalised iOS equivalents.
    PROP
    sed -i 's/^    //' mod/module.prop

    echo '#MAGISK' > mod/META-INF/com/google/android/updater-script

    echo "ui=$(ls "$UIDIR" | wc -l) notif=$(ls "$NDIR" | wc -l) ring=$(ls "$RDIR" | wc -l) alarm=$(ls "$ADIR" | wc -l)"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    ( cd mod && zip -qr "$out/iossounds.zip" . )
    runHook postInstall
  '';

  meta = {
    description = "Magisk module replacing Android system sounds with iOS ones";
    longDescription = ''
      Sources are read from a local Xcode iOS simulator runtime. Apple's audio
      is never vendored into this repository, which is public.
    '';
  };
}
