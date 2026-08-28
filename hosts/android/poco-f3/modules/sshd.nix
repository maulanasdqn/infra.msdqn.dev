{
  lib,
  stdenvNoCC,
  zip,
  # The client public key allowed to log in. Defaults to the key generated for
  # this phone; override to authorise a different machine.
  authorizedKey ? "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEB7+Hf65VGjC/eq6NbtGp+sNiIAFBq/TdV/SG0R+mTI poco-f3-nix",
  loginScript ? "/data/ssh/login.sh",
}:

stdenvNoCC.mkDerivation {
  pname = "magisk-sshd";
  version = "1.0";

  dontUnpack = true;
  nativeBuildInputs = [ zip ];

  buildPhase = ''
    runHook preBuild
    mkdir -p mod/META-INF/com/google/android

    cat > mod/module.prop <<PROP
    id=sshd
    name=OpenSSH server (native nix)
    version=v1.0
    versionCode=1
    author=ms
    description=Runs OpenSSH from the nix store on 127.0.0.1:8022, key-only, forced into the Nix root shell. Reach it with adb forward + ssh, no network exposure.
    PROP
    sed -i 's/^    //' mod/module.prop

    cp ${./sshd/post-fs-data.sh} mod/post-fs-data.sh
    cp ${./sshd/service.sh} mod/service.sh
    chmod 0644 mod/post-fs-data.sh mod/service.sh

    substituteInPlace mod/service.sh \
      --replace-fail '@login@' '${loginScript}' \
      --replace-fail '@authorizedKey@' ${lib.escapeShellArg authorizedKey}

    chmod 0755 mod/post-fs-data.sh mod/service.sh
    echo '#MAGISK' > mod/META-INF/com/google/android/updater-script

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    ( cd mod && zip -qr "$out/sshd.zip" . )
    runHook postInstall
  '';

  meta = {
    description = "Magisk module: native-nix OpenSSH on localhost for a real terminal over adb";
  };
}
