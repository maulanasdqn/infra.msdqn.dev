{
  pkgs,
  username,
  ...
}:
{
  home-manager.users.${username} = {
    programs.eww = {
      enable = true;
      configDir = ./eww;
    };

    home.packages = with pkgs; [
      jq
      socat
      wireplumber
      brightnessctl
    ];
  };
}
