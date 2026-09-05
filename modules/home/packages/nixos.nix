{
  pkgs,
  username,
  ...
}:
{
  home-manager.users.${username} = {

    imports = [ ./cli.nix ];

    home = {

      packages = with pkgs; [
        (callPackage ../../../pkgs/helium-browser { })
        google-chrome
        slack
        discord
      ];

      sessionVariables = {
        EDITOR = "nvim";
        GOPATH = "$HOME/go";
      };

      sessionPath = [
        "$HOME/.local/bin"
        "$HOME/go/bin"
        "$HOME/.bun/bin"
        "$HOME/.cargo/bin"
      ];
    };
  };
}
