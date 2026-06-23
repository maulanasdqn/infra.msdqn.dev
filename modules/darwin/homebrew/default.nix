{ enableLaravel, enableAggressiveTweaks ? false, lib, ... }:
{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      # "zap" removes unmanaged Homebrew packages + their data — fine on a single-owner
      # MacBook, destructive on the shared Mac mini (would wipe mrscrapersupport57's
      # formulae). "none" never touches packages the config doesn't declare.
      cleanup = if enableAggressiveTweaks then "zap" else "none";
    };

    brews = [
      # xcodegen is sourced from Homebrew rather than nixpkgs: 2.45+ requires
      # Swift 6, but nixpkgs' swift toolchain is still 5.10.1 (even on master),
      # so it can only build xcodegen 2.44.1. Homebrew ships the current release.
      "xcodegen"
    ]
    ++ lib.optionals enableLaravel [
      "mysql"
      "postgresql@16"
      "redis"
    ];

    casks = [
      "helium-browser"
      "discord"
      "slack"
      "figma"
      "pritunl"
      "postman"
    ];
  };
}
