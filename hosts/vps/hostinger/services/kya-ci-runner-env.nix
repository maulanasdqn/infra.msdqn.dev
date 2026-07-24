{ lib, pkgs, ... }:
let
  # The KYA CI workflow (s52ai/kya-group ci.yml) runs on these self-hosted
  # runners because the org's GitHub-hosted minutes are billing-blocked.
  # actions/setup-node and moonrepo/setup-toolchain download generic-linux
  # binaries; NixOS refuses to exec them unless NIX_LD points the stub loader
  # at a real dynamic linker. programs.nix-ld sets NIX_LD for login shells, but
  # a systemd service gets a clean environment, so the runners need it set
  # explicitly or every `node` invocation hits the stub and fails.
  ldEnv = {
    NIX_LD = lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";
    NIX_LD_LIBRARY_PATH = lib.makeLibraryPath (
      with pkgs;
      [
        stdenv.cc.cc.lib
        zlib
        openssl
        libuv
      ]
    );
    # moonrepo/setup-toolchain runs proto, which shells out to curl to fetch
    # moon and needs a CA bundle to verify the download over TLS.
    SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
  };
  ciTools = with pkgs; [
    curl
    cacert
    xz
    gnutar
    gzip
    unzip
  ];
in
{
  programs.nix-ld.enable = true;

  systemd.services = lib.genAttrs [
    "github-runner-kya-fq"
    "github-runner-kya-sr"
    "github-runner-kya-bc"
    "github-runner-kya-bp"
  ] (_: {
    environment = ldEnv;
    path = ciTools;
  });
}
