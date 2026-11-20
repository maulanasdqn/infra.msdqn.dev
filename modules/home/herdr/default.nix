{
  pkgs,
  username,
  ...
}:
{
  home-manager.users.${username} = {
    home.packages = [ pkgs.herdr ];

    xdg.configFile."herdr/config.toml".text = ''
      onboarding = false

      [theme]
      name = "rose-pine"

      [update]
      version_check = false

      [terminal]
      default_shell = "${pkgs.zsh}/bin/zsh"
      shell_mode = "auto"
      new_cwd = "follow"

      [keys]
      prefix = "ctrl+a"
      new_tab = "prefix+c"
      next_tab = "prefix+n"
      previous_tab = "prefix+p"
      close_tab = "prefix+shift+x"
      rename_tab = "prefix+shift+t"
      switch_tab = "prefix+1..9"

      focus_pane_left = "prefix+h"
      focus_pane_down = "prefix+j"
      focus_pane_up = "prefix+k"
      focus_pane_right = "prefix+l"

      split_vertical = "prefix+|"
      split_horizontal = "prefix+minus"
      close_pane = "prefix+x"
      zoom = "prefix+z"
      copy_mode = "prefix+["

      resize_pane_left = "prefix+shift+h"
      resize_pane_down = "prefix+shift+j"
      resize_pane_up = "prefix+shift+k"
      resize_pane_right = "prefix+shift+l"

      new_workspace = "prefix+shift+n"
      close_workspace = "prefix+shift+d"
      workspace_picker = "prefix+w"
      goto = "prefix+g"
      detach = "prefix+d"
      reload_config = "prefix+shift+r"
    '';
  };
}
