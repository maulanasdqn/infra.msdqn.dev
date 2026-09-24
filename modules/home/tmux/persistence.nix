{
  lib,
  pkgs,
  username,
  ...
}:
{
  home-manager.users.${username}.programs.tmux.extraConfig = lib.mkAfter ''
    set -g @continuum-restore 'on'
    set -g @continuum-save-interval '1'
    run-shell ${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/continuum.tmux
  '';
}
