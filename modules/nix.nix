{ ... }:
{
  nix.enable = false;
  determinateNix.customSettings = {
    eval-cores = 0;
    download-buffer-size = 134217728;
    auto-optimise-store = true;
    min-free = 10737418240;
    max-free = 53687091200;
    extra-experimental-features = [
      "build-time-fetch-tree"
      "parallel-eval"
    ];
    extra-substituters = [ "https://nix-on-droid.cachix.org" ];
    extra-trusted-public-keys = [ "nix-on-droid.cachix.org-1:56snoMJTXmDRC1Ei24CmKoUqZOperNq8/1S+LFagarA=" ];
  };

  launchd.daemons.nix-gc = {
    serviceConfig = {
      Label = "org.nixos.nix-gc";
      ProgramArguments = [
        "/nix/var/nix/profiles/default/bin/nix-collect-garbage"
        "--delete-older-than"
        "30d"
      ];
      StartCalendarInterval = [
        {
          Weekday = 0;
          Hour = 4;
          Minute = 0;
        }
      ];
      RunAtLoad = false;
      LowPriorityIO = true;
      Nice = 10;
      StandardOutPath = "/var/log/nix-gc.log";
      StandardErrorPath = "/var/log/nix-gc.log";
    };
  };
}
