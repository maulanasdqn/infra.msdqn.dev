{
  stdenvNoCC,
  zip,
  nameservers ? [
    "1.1.1.1"
    "1.0.0.1"
  ],
  store ? "/data/nix",
}:

stdenvNoCC.mkDerivation {
  pname = "magisk-nixbind";
  version = "1.0";

  dontUnpack = true;
  nativeBuildInputs = [ zip ];

  buildPhase = ''
    runHook preBuild
    mkdir -p mod/META-INF/com/google/android

    cat > mod/module.prop <<PROP
    id=nixbind
    name=Nix native store bind-mount
    version=v1.0
    versionCode=1
    author=ms
    description=Creates /nix and bind-mounts the Nix store so nix runs natively with no proot.
    PROP
    sed -i 's/^    //' mod/module.prop

    cp ${./post-fs-data.sh} mod/post-fs-data.sh
    chmod 0644 mod/post-fs-data.sh

    substituteInPlace mod/post-fs-data.sh \
      --replace-fail '@store@' '${store}' \
      --replace-fail '@resolv@' '${
        (builtins.concatStringsSep "" (map (n: "nameserver ${n}\\n") nameservers))
        + "options timeout:2 attempts:3\\n"
      }'

    chmod 0755 mod/post-fs-data.sh
    echo '#MAGISK' > mod/META-INF/com/google/android/updater-script

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    ( cd mod && zip -qr "$out/nixbind.zip" . )
    runHook postInstall
  '';

  meta = {
    description = "Magisk module that bind-mounts the Nix store to /nix";
  };
}
