{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage {
  pname = "parallax";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "maulanasdqn";
    repo = "parallax";
    rev = "a5ab7ce5427a2bce4de9457d81dec3c7cb7f96b7";
    hash = "sha256-b038oazBFFf6biUbW/NcEaRutQFYjc7MyUxCaFM/vCQ=";
  };

  cargoHash = "sha256-2Mj3ahZ/3HM7LVWiup8KCVRkpns7f9UBxuUzMfiKabA=";

  meta = with lib; {
    description = "Multi-protocol SOCKS5/HTTP proxy server";
    homepage = "https://github.com/maulanasdqn/parallax";
    license = licenses.mit;
    mainProgram = "parallax-server";
  };
}
