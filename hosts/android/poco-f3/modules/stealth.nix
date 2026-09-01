{
  stdenvNoCC,
  zip,
}:

stdenvNoCC.mkDerivation {
  pname = "magisk-stealth";
  version = "1.0";

  dontUnpack = true;
  nativeBuildInputs = [ zip ];

  buildPhase = ''
    runHook preBuild
    mkdir -p mod/META-INF/com/google/android

    cat > mod/module.prop <<PROP
    id=stealth
    name=Stealth props and boot state
    version=v1.0
    versionCode=1
    author=ms
    description=Spoofs verified boot state and build type, provides stealth frida-server wrapper.
    PROP
    sed -i 's/^    //' mod/module.prop

    cp ${./stealth/post-fs-data.sh} mod/post-fs-data.sh
    cp ${./stealth/service.sh} mod/service.sh
    chmod 0755 mod/post-fs-data.sh mod/service.sh

    mkdir -p mod/system/bin
    cp ${./stealth/frida-start.sh} mod/system/bin/frida-start
    cp ${./stealth/frida-stop.sh} mod/system/bin/frida-stop
    chmod 0755 mod/system/bin/frida-start mod/system/bin/frida-stop

    echo '#MAGISK' > mod/META-INF/com/google/android/updater-script

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    ( cd mod && zip -qr "$out/stealth.zip" . )
    runHook postInstall
  '';

  meta = {
    description = "KSU module spoofing boot/build properties for stealth";
  };
}
