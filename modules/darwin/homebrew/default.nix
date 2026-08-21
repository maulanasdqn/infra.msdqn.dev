{
  config,
  enableLaravel,
  enableAggressiveTweaks ? false,
  lib,
  ...
}:
{
  homebrew = {
    enable = true;
    taps = builtins.attrNames config.nix-homebrew.taps;
    onActivation = {
      autoUpdate = true;
      cleanup = if enableAggressiveTweaks then "zap" else "none";
    };

    brews = [
      "xcodegen"
      "swiftlint"
    ]
    ++ lib.optionals enableLaravel [
      "mysql"
      "postgresql@16"
      "redis"
    ];

    casks = [
      "chromium"
      "helium-browser"
      "slack"
      "figma"
      "pritunl"
      "postman"
      "microsoft-teams"
    ]
    # No Discord on the mac mini.
    ++ lib.optionals (config.networking.hostName != "macmini-mrscraper") [
      "discord"
    ];
  };
}
