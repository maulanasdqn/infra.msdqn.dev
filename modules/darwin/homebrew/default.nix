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
