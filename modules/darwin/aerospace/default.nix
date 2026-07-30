{
  config,
  pkgs,
  lib,
  username,
  enableTilingWM,
  ...
}:
let
  # Top gap is derived, not eyeballed — AeroSpace measures outer.top from the
  # system work-area top, but the sketchybar islands are drawn from screen-top, so
  # the two live in different origins and the offset has to be cancelled out:
  #
  #   topGap = islandBottom + desiredGap - workAreaTop
  #
  #   islandBottom = bar y_offset + (bar height + island height) / 2
  #                = 8 + (34 + 30) / 2 = 40px   (see the sketchybar module)
  #   desiredGap   = 10px, to match outer.left/right/bottom below
  #   workAreaTop  = NSScreen visibleFrame inset, per host:
  #                  - Notched MacBook: menu bar stays reserved → 33px (measured).
  #                    sketchybar just draws over that strip (topmost=window).
  #                  - Mac mini on an external display: menu bar is auto-hidden,
  #                    so the work area starts at screen-top → 0px.
  #
  # → MacBook: 40 + 10 - 33 = 17   → Mac mini: 40 + 10 - 0 = 50
  #
  # Retuning the bar's y_offset/height changes islandBottom, so recompute both.
  topGap = if config.networking.hostName == "macmini-mrscraper" then 50 else 17;
  aerospaceConfig = pkgs.writeText "aerospace.toml" ''
    # Rosé Pine — Aerospace tiling WM
    # Keybinds mirror workstation (Hyprland/SUPER → macOS/cmd)

    # config-version 2 has exactly one breaking change over the implicit v1:
    # persistent-workspaces no longer falls back to the set AeroSpace infers by
    # scanning `workspace X` on the right-hand side of key bindings — the fallback
    # is now an empty array. So it has to be declared, or every empty workspace
    # would be discarded the moment it lost its last window.
    config-version = 2

    # Exactly the set v1 inferred from the alt-1..9 bindings below (verified with
    # `aerospace list-workspaces --all` before the migration). sketchybar only
    # draws indicators for 1–6, but the bindings reach 9, so all nine stay.
    persistent-workspaces = ['1', '2', '3', '4', '5', '6', '7', '8', '9']

    # Startup is owned by the nix-managed launchd agent below (RunAtLoad +
    # KeepAlive), NOT AeroSpace's own login item. The login item is unreliable
    # across reboots (macOS can leave it unapproved/disabled → no gaps on boot).
    start-at-login = false

    exec-on-workspace-change = [
      '/bin/bash', '-c',
      "/usr/local/bin/sketchybar --trigger aerospace_workspace_change AEROSPACE_FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE"
    ]

    # Restore the window layout after a reboot. AeroSpace starts at login (via the
    # launchd agent below) and launches these apps; the [[on-window-detected]]
    # rules at the bottom then pin each one to its workspace. Together they
    # reproduce the saved layout hands-free on every boot.
    after-startup-command = [
      'exec-and-forget open -b net.kovidgoyal.kitty',
      'exec-and-forget open -b net.imput.helium',
      'exec-and-forget open -b com.tinyspeck.slackmacgap',
      'exec-and-forget open -b com.hnc.Discord',
    ]

    [key-mapping]
    preset = 'qwerty'

    [gaps]
    inner.horizontal = 8
    inner.vertical   = 8
    outer.left       = 10
    outer.bottom     = 10
    # Host-specific and derived from the sketchybar geometry — see topGap above.
    outer.top        = ${toString topGap}
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

    # ── Window → workspace assignment (restores layout after reboot) ──────────
    # Captured from the live layout. Whenever one of these apps opens a window
    # (including the after-startup-command launches above), it's moved to its
    # workspace. Edit a number here to remap, or add a block for a new app
    # (find its id with: aerospace list-windows --all --format '%{app-bundle-id}').
    [[on-window-detected]]
    if.app-id = 'net.kovidgoyal.kitty'
    run = 'move-node-to-workspace 1'

    [[on-window-detected]]
    if.app-id = 'net.imput.helium'
    run = 'move-node-to-workspace 2'

    [[on-window-detected]]
    if.app-id = 'com.tinyspeck.slackmacgap'
    run = 'move-node-to-workspace 3'

    [[on-window-detected]]
    if.app-id = 'com.hnc.Discord'
    run = 'move-node-to-workspace 5'
  '';
in
lib.mkIf enableTilingWM {
  environment.systemPackages = [ pkgs.aerospace ];

  home-manager.users.${username} = {
    home.file.".aerospace.toml".source = aerospaceConfig;
  };

  # Launch AeroSpace at login via a nix-managed user agent instead of AeroSpace's
  # own start-at-login login item (which macOS can silently disable across
  # reboots, leaving you with no tiling gaps). KeepAlive restarts it if it dies.
  # Mirrors the sketchybar agent so the gaps + bar always come back on boot.
  launchd.user.agents.aerospace = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.aerospace}/Applications/AeroSpace.app/Contents/MacOS/AeroSpace"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/aerospace.out.log";
      StandardErrorPath = "/tmp/aerospace.err.log";
    };
  };
}
