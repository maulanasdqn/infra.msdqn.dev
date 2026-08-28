{
  stdenvNoCC,
  fetchurl,
  zip,
  # StevenBlack unified hosts (adware + malware). Pinned by commit so the build
  # is reproducible; bump rev+hash to update the blocklist.
  rev ? "fbfd5ca4e9f278f671607dfb085c090d6f606111",
  hash ? "sha256-Oi89zjMbvPtMR3c1w10nJd+zh++5W/O6x19TPvMMkj0=",
}:

let
  blocklist = fetchurl {
    url = "https://raw.githubusercontent.com/StevenBlack/hosts/${rev}/hosts";
    inherit hash;
  };
in

stdenvNoCC.mkDerivation {
  pname = "magisk-adblock";
  version = "1.0";

  dontUnpack = true;
  nativeBuildInputs = [ zip ];

  buildPhase = ''
    runHook preBuild
    mkdir -p mod/system/etc mod/META-INF/com/google/android

    # Android's bionic resolver consults /system/etc/hosts before it hits DNS,
    # so this blocks for every app and survives DNS-over-TLS (verified: a hosts
    # entry resolved even with private_dns_mode=strict). Magisk magic-mounts
    # this file over the real one; the base OS file is untouched.
    {
      printf '127.0.0.1 localhost\n::1 ip6-localhost\n\n'
      # StevenBlack maps to 0.0.0.0; keep that (drops the packet with no
      # loopback service to hit) and strip comments/blanks to keep it small.
      grep '^0\.0\.0\.0 ' ${blocklist} | awk '$2 != "0.0.0.0" {print $1" "$2}'
    } > mod/system/etc/hosts

    cat > mod/module.prop <<PROP
    id=adblock
    name=System-wide hosts adblock
    version=v1.0-${builtins.substring 0 7 rev}
    versionCode=1
    author=ms
    description=Blocks ads and trackers for every app via /system/etc/hosts (StevenBlack unified list). Works under DNS-over-TLS.
    PROP
    sed -i 's/^    //' mod/module.prop

    echo '#MAGISK' > mod/META-INF/com/google/android/updater-script

    echo "blocked domains: $(grep -c '^0\.0\.0\.0 ' mod/system/etc/hosts)"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    ( cd mod && zip -qr "$out/adblock.zip" . )
    runHook postInstall
  '';

  meta = {
    description = "Magisk module: system-wide hosts-based ad/tracker blocking";
  };
}
