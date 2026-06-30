{
  pkgs,
  username,
  claude-desktop,
  ...
}:
{
  home-manager.users.${username} = {
    # Shared CLI tools (also used by nix-on-droid/honor).
    imports = [ ./cli.nix ];

    home = {
      # GUI / desktop-only apps (workstation-specific).
      packages = with pkgs; [
        claude-desktop.packages.${pkgs.system}.claude-desktop-with-fhs
        (callPackage ../../../pkgs/helium-browser { })
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
