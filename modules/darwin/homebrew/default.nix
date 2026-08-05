{
  enableLaravel,
  enableAggressiveTweaks ? false,
  lib,
  ...
}:
{
  homebrew = {
    enable = true;
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
      "helium-browser"
      "discord"
      "slack"
      "figma"
      "pritunl"
      "postman"
      "microsoft-teams"
    ];
  };
}
