{
  stdenvNoCC,
  zip,
}:

stdenvNoCC.mkDerivation {
  pname = "magisk-nixenter";
  version = "1.0";

  dontUnpack = true;
  nativeBuildInputs = [ zip ];

  buildPhase = ''
    runHook preBuild
    mkdir -p mod/system/bin mod/system/etc mod/META-INF/com/google/android

    # Ship the launcher as a real module file so Magisk magic-mounts it onto
    # /system/bin — on PATH for any terminal, no runtime symlinking to go stale.
    cp ${./nixenter/nix-enter.sh} mod/system/bin/nix-enter
    chmod 0755 mod/system/bin/nix-enter

    # `ne` is a short alias that just forwards to nix-enter.
    printf '#!/system/bin/sh\nexec /system/bin/nix-enter "$@"\n' > mod/system/bin/ne
    chmod 0755 mod/system/bin/ne

    # Overlay /system/etc/mkshrc so an interactive terminal-app shell drops
    # straight into the Nix root shell. The USER_ID>=10000 guard means this
    # never affects adb (uid 2000) or root (uid 0).
    cp ${./nixenter/mkshrc} mod/system/etc/mkshrc
    chmod 0644 mod/system/etc/mkshrc

    cat > mod/module.prop <<PROP
    id=nixenter
    name=nix-enter terminal helper
    version=v1.0
    versionCode=1
    author=ms
    description=Adds nix-enter and ne to PATH: drop into a root shell with the native Nix environment loaded, from Termux or any terminal.
    PROP
    sed -i 's/^    //' mod/module.prop

    echo '#MAGISK' > mod/META-INF/com/google/android/updater-script

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    ( cd mod && zip -qr "$out/nixenter.zip" . )
    runHook postInstall
  '';

  meta = {
    description = "Magisk module: nix-enter helper to reach native Nix from a terminal";
  };
}
