{
  pkgs,
  nixvim,
  claude-code,
  ...
}:

{
  imports = [
    ../../../modules/home/zsh/hm.nix
    ../../../modules/home/starship/hm.nix
    ../../../modules/home/neovim/hm.nix
    ../../../modules/home/packages/cli.nix
  ];

  home = {
    username = "root";
    homeDirectory = "/data/local/nixhome";
    stateVersion = "24.05";

    sessionVariables = {
      NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      NIX_CONF_DIR = "/nix/etc";
      # Android/glibc default is the C (ASCII) locale, so starship's glyphs fail
      # iconv on every prompt. C.UTF-8 is built into glibc, no archive needed.
      LANG = "C.UTF-8";
      LC_ALL = "C.UTF-8";
    };
  };

  programs.home-manager.enable = true;

  # oh-my-zsh's git plugin + update checker needs git on PATH. The shared git
  # module wraps itself in home-manager.users.<name> (darwin/NixOS style) so it
  # can't be imported into this standalone config; enable git directly.
  programs.git.enable = true;

  # The home-manager reference manpage derivation fails to build on this
  # aarch64-linux target (nixos-render-docs tooling gap), which otherwise fails
  # the whole activation. It is only docs — skip it.
  manual.manpages.enable = false;
  news.display = "silent";
}
