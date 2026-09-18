{
  config,
  lib,
  pkgs,
  ...
}:
let

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

  systemd.services = lib.mapAttrs' (
    name: _:
    lib.nameValuePair "github-runner-${name}" {
      environment = ldEnv;
      path = ciTools;
    }
  ) config.services.github-runners;
}
