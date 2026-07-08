{ username, ... }:
{
  home-manager.users.${username}.programs.git = {
    enable = true;
    # home.stateVersion is < 25.05, so the git module still defaults
    # signing.format to "openpgp". Set it explicitly to silence the
    # deprecation warning (no signing key is configured, so this is inert).
    signing.format = "openpgp";
    settings = {
      user.name = "maulanasdqn";
      user.email = "maulanasdqn@gmail.com";
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
    };
  };
}
