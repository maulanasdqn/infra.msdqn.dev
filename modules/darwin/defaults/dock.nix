{ ... }:
{
  system.defaults.dock = {
    autohide = true;
    autohide-delay = 0.5;
    autohide-time-modifier = 1.0;
    expose-animation-duration = 0.2;
    launchanim = true;
    show-recents = false;
    tilesize = 48;
    magnification = false;
    mineffect = "genie";
    orientation = "bottom";
    persistent-apps = [ ];
    static-only = false;
    mru-spaces = false;
    minimize-to-application = true;
  };

  system.defaults.spaces = {
    spans-displays = false;
  };
}
