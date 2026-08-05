{
  pkgs,
  username,
  ...
}:
{
  home-manager.users.${username} = {
    programs.eww = {
      enable = true;
      yuckConfig = builtins.readFile ./eww/eww.yuck;
      scssConfig = builtins.readFile ./eww/eww.scss;
    };

    home.packages = with pkgs; [
      jq
      socat
      wireplumber
      brightnessctl
    ];
  };
}
