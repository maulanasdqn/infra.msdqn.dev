{
  pkgs,
  lib,
  username,
  enableTilingWM,
  ...
}:
let
  aerospaceConfig = pkgs.writeText "aerospace.toml" ''
    # Rosé Pine — Aerospace tiling WM
    # Keybinds mirror workstation (Hyprland/SUPER → macOS/cmd)

    start-at-login = true

    exec-on-workspace-change = [
      '/bin/bash', '-c',
      "/usr/local/bin/sketchybar --trigger aerospace_workspace_change AEROSPACE_FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE"
    ]

    [key-mapping]
    preset = 'qwerty'

    [gaps]
    inner.horizontal = 8
    inner.vertical   = 8
    outer.left       = 10
    outer.bottom     = 10
    # outer.top is measured from the system-reserved region top (~27px on a
    # notched MacBook), not the screen top. The sketchybar (y_offset 8 +
    # height 40) floats over that and renders down to ~43px. Stacking the full
    # bar height here left a ~36px gap; 26px clears the bar with a 10px
    # breathing gap that matches the side/bottom gaps.
    outer.top        = 26
    outer.right      = 10

    [mode.main.binding]
    # Terminal / launcher
    alt-enter   = 'exec-and-forget open -n $HOME/Applications/Home\ Manager\ Trampolines/kitty.app'
    alt-d       = 'exec-and-forget open -a Raycast'
    alt-b       = 'exec-and-forget open -a Helium'

    # Window focus (vim-style, mirrors $mod + hjkl on workstation)
    alt-h = 'focus left'
    alt-j = 'focus down'
    alt-k = 'focus up'
    alt-l = 'focus right'

    # Window move
    alt-shift-h = 'move left'
    alt-shift-j = 'move down'
    alt-shift-k = 'move up'
    alt-shift-l = 'move right'

    # Window resize
    alt-ctrl-h = 'resize width -50'
    alt-ctrl-j = 'resize height +50'
    alt-ctrl-k = 'resize height -50'
    alt-ctrl-l = 'resize width +50'

    # Workspace switch
    alt-1 = 'workspace 1'
    alt-2 = 'workspace 2'
    alt-3 = 'workspace 3'
    alt-4 = 'workspace 4'
    alt-5 = 'workspace 5'
    alt-6 = 'workspace 6'
    alt-7 = 'workspace 7'
    alt-8 = 'workspace 8'
    alt-9 = 'workspace 9'

    # Move window to workspace + follow
    alt-shift-1 = ['move-node-to-workspace 1', 'workspace 1']
    alt-shift-2 = ['move-node-to-workspace 2', 'workspace 2']
    alt-shift-3 = ['move-node-to-workspace 3', 'workspace 3']
    alt-shift-4 = ['move-node-to-workspace 4', 'workspace 4']
    alt-shift-5 = ['move-node-to-workspace 5', 'workspace 5']
    alt-shift-6 = ['move-node-to-workspace 6', 'workspace 6']
    alt-shift-7 = ['move-node-to-workspace 7', 'workspace 7']
    alt-shift-8 = ['move-node-to-workspace 8', 'workspace 8']
    alt-shift-9 = ['move-node-to-workspace 9', 'workspace 9']

    # Layout
    alt-t       = 'layout floating tiling'
    alt-shift-f = 'fullscreen'
    alt-e       = 'layout tiles horizontal vertical'
    alt-r       = 'layout accordion horizontal vertical'

    # Window / system
    alt-shift-q = 'close'
    alt-shift-b = 'exec-and-forget /usr/local/bin/sketchybar --bar hidden=toggle'
    alt-ctrl-0  = 'exec-and-forget pmset displaysleepnow'
    alt-shift-r = 'reload-config'
  '';
in
lib.mkIf enableTilingWM {
  environment.systemPackages = [ pkgs.aerospace ];

  home-manager.users.${username} = {
    home.file.".aerospace.toml".source = aerospaceConfig;
  };
}
