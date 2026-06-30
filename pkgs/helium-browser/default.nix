{
  lib,
  fetchurl,
  appimageTools,
}:
let
  pname = "helium-browser";
  version = "0.12.4.1";

  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64.AppImage";
    hash = "sha256-OgS8HkLBseFrEhNFJxMwp1bg0gzPdfY1VaySAAp7vq0=";
  };

  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm644 ${appimageContents}/helium.desktop $out/share/applications/helium.desktop
    install -Dm644 ${appimageContents}/helium.png \
      $out/share/icons/hicolor/256x256/apps/helium.png
    substituteInPlace $out/share/applications/helium.desktop \
      --replace-quiet 'Exec=AppRun' "Exec=$out/bin/${pname}"

    # Enable VAAPI hardware video decode on the AMD iGPU under Wayland/Ozone.
    # The chrome://flags toggle alone does NOT route decode through VAAPI on
    # Linux GL — VaapiVideoDecodeLinuxGL is required. Renoir's VCN decodes
    # H264/HEVC/VP9 (no AV1), so AV1 streams still fall back to software.
    # makeWrapper isn't in scope here, so emit a plain POSIX wrapper.
    mv $out/bin/${pname} $out/bin/.${pname}-wrapped
    printf '#!/bin/sh\nexec %s --enable-features=VaapiVideoDecodeLinuxGL,VaapiIgnoreDriverChecks --ignore-gpu-blocklist --enable-zero-copy "$@"\n' "$out/bin/.${pname}-wrapped" > $out/bin/${pname}
    chmod +x $out/bin/${pname}
  '';

  meta = with lib; {
    description = "Privacy-focused Chromium-based browser by imputnet";
    homepage = "https://helium.computer/";
    license = licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
