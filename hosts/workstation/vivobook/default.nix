{
  config,
  lib,
  pkgs,
  username,
  enableTilingWM,
  ...
}:
{
  imports = [
    ./hardware.nix
    ../../../profiles/workstation.nix
  ];

  networking.hostName = "vivobook";

  services.logind = {
    lidSwitch = lib.mkForce "ignore";
    lidSwitchExternalPower = lib.mkForce "ignore";
    lidSwitchDocked = lib.mkForce "ignore";
  };

  services.motion = {
    enable = true;
    extraConfig = ''
      videodevice /dev/video0
      v4l2_palette 8
      width 1280
      height 720
      framerate 15
      threshold 3000
      minimum_motion_frames 3
      event_gap 10
      pre_capture 3
      post_capture 5
      picture_output best
      picture_filename %Y%m%d/%H%M%S-%q
      movie_output on
      movie_filename %Y%m%d/%H%M%S
      movie_codec mkv
      movie_quality 75
      target_dir /var/lib/motion
      stream_port 8081
      stream_quality 75
      stream_maxrate 15
      stream_localhost off
      webcontrol_port 8080
      webcontrol_localhost off
    '';
  };

  networking.firewall.allowedTCPPorts = [ 8080 8081 ];
}
