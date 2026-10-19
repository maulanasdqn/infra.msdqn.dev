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

      [keys]
      prefix = "ctrl+a"
      split_vertical = "prefix+v"
      split_horizontal = "prefix+minus"
      focus_pane_left = "prefix+h"
      focus_pane_down = "prefix+j"
      focus_pane_up = "prefix+k"
      focus_pane_right = "prefix+l"
      new_tab = "prefix+c"
      previous_tab = "prefix+p"
      next_tab = "prefix+n"
      switch_tab = "prefix+1..9"
      workspace_picker = "prefix+w"
      goto = "prefix+g"
      zoom = "prefix+z"
      detach = "prefix+d"
      reload_config = "prefix+shift+r"
    '';
  };
}
