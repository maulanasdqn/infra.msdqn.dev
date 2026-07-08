{ ... }:
{
  nix.enable = false;
  determinateNix.customSettings = {
    eval-cores = 0;
    download-buffer-size = 134217728; # 128 MiB
    extra-experimental-features = [
      "build-time-fetch-tree"
      "parallel-eval"
    ];
    extra-substituters = [ "https://nix-on-droid.cachix.org" ];
    extra-trusted-public-keys = [ "nix-on-droid.cachix.org-1:56snoMJTXmDRC1Ei24CmKoUqZOperNq8/1S+LFagarA=" ];
  };
}
