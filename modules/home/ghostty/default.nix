{ pkgs, username, ... }:
{
  home-manager.users.${username}.programs.ghostty = {
    enable = true;
    package = pkgs.ghostty-bin;
    enableZshIntegration = true;
    settings = {
      font-family = "JetBrainsMono Nerd Font";
      font-size = 14;

      background = "#191724";
      foreground = "#e0def4";
      cursor-color = "#e0def4";
      cursor-text = "#191724";
      cursor-style = "block";
      cursor-style-blink = true;
      selection-background = "#403d52";
      selection-foreground = "#e0def4";

      palette = [
        "0=#26233a"
        "1=#eb6f92"
        "2=#31748f"
        "3=#f6c177"
        "4=#9ccfd8"
        "5=#c4a7e7"
        "6=#ebbcba"
        "7=#e0def4"
        "8=#6e6a86"
        "9=#eb6f92"
        "10=#31748f"
        "11=#f6c177"
        "12=#9ccfd8"
        "13=#c4a7e7"
        "14=#ebbcba"
        "15=#e0def4"
      ];

      background-opacity = 0.9;
      background-blur = 50;
      window-padding-x = 10;
      window-padding-y = 10;
      confirm-close-surface = false;
      shell-integration-features = "ssh-env,ssh-terminfo";

      macos-titlebar-style = "hidden";
      macos-option-as-alt = true;

      clipboard-read = "allow";
      clipboard-write = "allow";

      keybind = [ "shift+enter=text:\\x1b[13;2u" ];
    };
  };
}
