{ username, ... }:
{
  home-manager.users.${username}.programs.kitty = {
    enable = true;
    settings = {
      font_family = "JetBrainsMono Nerd Font";
      font_size = 14;

      background = "#191724";
      foreground = "#e0def4";
      cursor = "#e0def4";
      cursor_text_color = "#191724";
      cursor_shape = "block";
      cursor_blink_interval = "0.5";
      selection_background = "#403d52";
      selection_foreground = "#e0def4";

      color0 = "#26233a";
      color1 = "#eb6f92";
      color2 = "#31748f";
      color3 = "#f6c177";
      color4 = "#9ccfd8";
      color5 = "#c4a7e7";
      color6 = "#ebbcba";
      color7 = "#e0def4";
      color8 = "#6e6a86";
      color9 = "#eb6f92";
      color10 = "#31748f";
      color11 = "#f6c177";
      color12 = "#9ccfd8";
      color13 = "#c4a7e7";
      color14 = "#ebbcba";
      color15 = "#e0def4";

      background_opacity = "0.9";
      background_blur = 50;
      window_padding_width = 10;
      confirm_os_window_close = 0;
      enable_audio_bell = false;
      shell_integration = "enabled";

      macos_titlebar_color = "background";
      macos_option_as_alt = "yes";
      hide_window_decorations = "titlebar-only";

      clipboard_control = "write-clipboard write-primary read-clipboard read-primary";
    };
    keybindings = {
      "shift+enter" = "send_text all \\x1b[13;2u";
    };
  };
}
