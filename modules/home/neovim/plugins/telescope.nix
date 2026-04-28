{ username, ... }:
{
  home-manager.users.${username}.programs.nixvim.plugins.telescope = {
    enable = true;
    extensions.fzf-native.enable = false;
    settings = {
      defaults = {
        path_display = [ "smart" ];
        mappings = {
          i = {
            "<C-k>".__raw = "require('telescope.actions').move_selection_previous";
            "<C-j>".__raw = "require('telescope.actions').move_selection_next";
          };
        };
      };
    };
  };
}
