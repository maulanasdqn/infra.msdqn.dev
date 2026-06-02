{ enableLaravel, lib, ... }:
{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
    };

    brews = lib.optionals enableLaravel [
      "mysql"
      "postgresql@16"
      "redis"
    ];

    casks = [
      "hammerspoon"
      "ghostty"
      "google-chrome"
      "firefox"
      "discord"
      "slack"
      "figma"
      "pritunl"
      "postman"
    ];
  };
}
