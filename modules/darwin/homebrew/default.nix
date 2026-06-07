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
      "helium-browser"
      "firefox"
      "discord"
      "slack"
      "figma"
      "pritunl"
      "postman"
    ];
  };
}
