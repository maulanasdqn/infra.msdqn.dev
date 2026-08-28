{
  stdenvNoCC,
  zip,
  rebootIdleHours ? 18,
  radioIdleMinutes ? 15,
}:

stdenvNoCC.mkDerivation {
  pname = "magisk-hardening";
  version = "1.0";

  dontUnpack = true;
  nativeBuildInputs = [ zip ];

  buildPhase = ''
    runHook preBuild
    mkdir -p mod/META-INF/com/google/android

    cat > mod/module.prop <<PROP
    id=hardening
    name=Privacy and kernel hardening
    version=v1.0
    versionCode=1
    author=ms
    description=Kernel sysctl hardening, privacy-first defaults, idle radio shutdown and auto-reboot to BFU.
    PROP
    sed -i 's/^    //' mod/module.prop

    cp ${./hardening/sysctl.sh} mod/post-fs-data.sh
    cp ${./hardening/service.sh} mod/service.sh
    chmod 0644 mod/post-fs-data.sh mod/service.sh

    substituteInPlace mod/service.sh \
      --replace-fail '@rebootIdleHours@' '${toString rebootIdleHours}' \
      --replace-fail '@radioIdleMinutes@' '${toString radioIdleMinutes}'

    chmod 0755 mod/post-fs-data.sh mod/service.sh
    echo '#MAGISK' > mod/META-INF/com/google/android/updater-script

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    ( cd mod && zip -qr "$out/hardening.zip" . )
    runHook postInstall
  '';

  meta = {
    description = "Magisk module applying GrapheneOS-inspired hardening to LineageOS";
  };
}
